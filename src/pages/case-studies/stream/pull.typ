#import "../../stdlib.typ": exercise, solution
== Stream Semantics

In the last section we saw the importance of clear thinking about semantics,
as our muddy thinking had led to mistakes in the design of the interpreter and the API we exposed to the user.
It's time to be more precise about the semantics of `Stream`.

We need to introduce some concepts so we can discuss semantics.
Let's start with *source* and *sink*.
Data orginates from a source, and finishes at a sink.
We can have multiple sources, but in our design there is only one sink.
The sink is downstream of the sources and any other intermediate nodes.
Similarly, the sources are upstream of the sink and any other intermediate nodes.

Data only flows in response to demand.
In our system, calls to `next` indicate demand for data.
Hence demand flows upstream while data flows downstream.
This is known as a *pull-based* approach.
It's the natural approach when using the programming strategies,
but it's not the only approach.
The obvious alternative is *push-based*,
but hybrid *push-pull* strategies are also possible.
We'll discuss these in more detail in a bit,
but right now I want to implement a feature that will help ground the discussion above.

Let's implement the method `filter`:

```scala
def filter(pred: A => Boolean): Stream[A]
```

This will have similar semantics to the method of the same name on `List`:
the resulting `Stream` will only contain elements for which the given predicate returns `true`.

Have a good at implementing this yourself before reading on, as it will help ground the discussion.
At this point the implementation technique should be fairly straightforward.
The `Stream` code is getting fairly lengthy, and its only the interpreter loop that is important, so I'll only include the interpreter code here.
You probably wrote something like

```scala
def next[C](compiled: Compiled[C]): Option[C] =
  compiled match
    // ...
    case Compiled.Filter(source, predicate) =>
      // Do filtering here 
```

The most straightforward way to implement filtering is to repeatedly pull data from the upstream until the upstream ends or we find a value that passes the predicate.

```scala
def next[C](compiled: Compiled[C]): Option[C] =
  compiled match
    // ...
    case Compiled.Filter(source, predicate) =>
      def loop(): Option[A] =
        next(source) match
          case None => None
          case Some(value) =>
            if pred(value) then Some(value) else loop()
```

This approach can lead to some problems.
Consider the following `Stream`.

```scala
Stream.fromIterator(Iterator.continually(1))
  .filter(_ != 1)
  .merge(Stream.fromSeq(2))
```

The left-hand side of the `merge` will never produce any values due to the `filter`.
However, the overall `Stream` could produce the single value from the right-hand side,
if `merge` ever pulls from that side.

