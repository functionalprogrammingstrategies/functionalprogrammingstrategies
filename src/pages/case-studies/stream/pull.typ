#import "../../stdlib.typ": exercise, solution
== Stream Semantics

In the last section we saw the importance of clear thinking about semantics,
as our muddy thinking led to mistakes in the design of the interpreter and the API.

To be able to talk precisely about semantics,
we need to introduce some terminology.
Let's start with *source* and *sink*.
Data orginates from a source, such as `fromIterator` or `fromSeq`, and finishes at a sink.
We can have multiple sources, but in our design there is only one sink.
The sink is *downstream* of the sources and any other intermediate nodes.
Similarly, the sources are *upstream* of the sink and any other intermediate nodes.

Data only flows in response to *demand*.
In our system, calls to `next` indicate demand for data.
Hence demand flows upstream while data flows downstream.
This is known as a *pull-based* approach, as the demand "pulls" data from the upstream nodes.
The pull-based approach is the natural approach when using the programming strategies,
but it's not the only approach.
In a later section we'll discuss alternatives
but right now I want to implement a feature that will help ground the discussion above.

Let's implement the method `filter`, with the signature shown below.

```scala
def filter(pred: A => Boolean): Stream[A]
```

This will have similar semantics to the method of the same name on `List`:
the resulting `Stream` will only produce elements for which the given predicate returns `true`.

Have a go at implementing this yourself before reading on.
At this point the implementation technique should be fairly straightforward.
The `Stream` code is getting fairly lengthy,
and only the interpreter loop is important,
so I'll only include the interpreter code here.

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
  .merge(Stream.fromSeq(Seq(2)))
```

The left-hand side of the `merge` will never produce any values due to the `filter`.
The overall `Stream` could produce the single value from the right-hand side,
if `merge` ever has the chance to pull from that side.
However, with our current implementation this will never occur,
as `merge` will be stuck forever in the left-hand side.

The underlying problem is that we've allowed `filter` to turn a single pull from the downstream
into an unbounded number of pulls from the upstream.
This suggests a principle we should maintain: a single pull from the downstream results in a single pull to the upstream.
Making this change requires that a pull can produce one of three outcomes: a value, the end of the stream, or a signal that no value is available now but may be available later.
Concretely, this means that `next` should produce an algebraic data type like

```scala mdoc:silent
enum Emit[+A]:
  // The pull produced a value
  case Value(get: A)
  // There is no value available now, but there may be in the future
  case Wait
  // The stream has ended and no values will ever be available
  case End
```


#exercise[Stream Emit]

Refactor the implementation of `Stream` so that `next` returns the `Emit` algebraic data type,
and change `filter` to produce a `Wait` value when the result of an upstream pull is not a value that passes the predicate.

#solution[
    This requires a lot of changes to the code. Most of the changes are quite straightforward, but `product` becomes substantially more complex now we have to account for one side producing a value while the otherside is still waiting. I felt the code was getting a bit messy, so refactored my implementation to define the `next` method within the `Compiled` type. In production code I'd probably rewrite the `Compiled` type into object-oriented style, to encapsulate the state, and also make sure it was only visible within the package that includes it and `Stream`.

```scala mdoc:silent:reset
import cats.syntax.all.*

enum Stream[A]:
  case Filter(source: Stream[A], predicate: A => Boolean)
  case Map[A, B](source: Stream[A], f: A => B)
      extends Stream[B]
  case Merge(left: Stream[A], right: Stream[A])
  case Product[A, B](left: Stream[A], right: Stream[B])
      extends Stream[(A, B)]
  case Take(source: Stream[A], count: Int)
  case FromIterator(it: Iterator[A])
  case FromSeq(seq: Seq[A])

  def filter(pred: A => Boolean): Stream[A] =
    Filter(this, pred)

  def map[B](f: A => B): Stream[B] =
    Map(this, f)

  def merge(that: Stream[A]): Stream[A] =
    Merge(this, that)

  def product[B](that: Stream[B]) =
    Product(this, that)

  def take(count: Int): Stream[A] =
    Take(this, count)

  def foldLeft[B](zero: B)(f: (B, A) => B): B =
    import Stream.Compiled
    import Stream.Emit

    val compiled = Compiled.fromStream(this)

    def loop(zero: B): B =
      compiled.next() match
        case Emit.Value(v) => loop(f(zero, v))
        case Emit.Wait     => loop(zero)
        case Emit.End      => zero

    loop(zero)

  def toSeq: Seq[A] =
    foldLeft(Seq.empty)(_ :+ _)

object Stream:
  enum Emit[+A]:
    // The pull produced a value
    case Value(get: A)
    // There is not value available now, but may be in the future
    case Wait
    // The stream has ended and no values will be available
    case End

    def map[B](f: A => B): Emit[B] =
      this match
        case Value(get) => Value(f(get))
        case Wait       => Wait
        case End        => End

    def flatMap[B](f: A => Emit[B]): Emit[B] =
      this match
        case Value(get) => f(get)
        case Wait       => Wait
        case End        => End

  enum MergeDirection:
    case PullLeft
    case PullRight

  enum ProductState[+A, +B]:
    // Pull from both left and right
    case Continue
    // Right value is cached. Pull from left
    case CacheRight(right: B)
    // Left value is cached. Pull from right
    case CacheLeft(left: A)
    // Upstream has ended
    case End

  enum Compiled[A]:
    case Filter(
        source: Compiled[A],
        predicate: A => Boolean
    )
    case Map[A, B](source: Compiled[A], f: A => B)
        extends Compiled[B]
    case Merge(
        left: Compiled[A],
        right: Compiled[A],
        var direction: MergeDirection
    )
    case Product[A, B](
        left: Compiled[A],
        right: Compiled[B],
        var state: ProductState[A, B]
    ) extends Compiled[(A, B)]
    case Take(source: Compiled[A], var count: Int)
    case FromIterator(it: Iterator[A])
    case FromSeq(seq: Seq[A], var idx: Int = 0)

    def next(): Emit[A] =
      this match
        case Compiled.Filter(source, pred) =>
          source
            .next()
            .flatMap(a =>
              if pred(a) then Emit.Value(a) else Emit.Wait
            )
        case Compiled.Map(source, f) => source.next().map(f)
        case c @ Compiled.Merge(left, right, direction) =>
          direction match
            case MergeDirection.PullLeft =>
              c.direction = MergeDirection.PullRight
              left.next()
            case MergeDirection.PullRight =>
              c.direction = MergeDirection.PullLeft
              right.next()
        case c @ Compiled.Product(left, right, state) =>
          import ProductState.*

          state match
            case End      => Emit.End
            case Continue =>
              (left.next(), right.next()) match
                case (Emit.End, _) =>
                  c.state = End
                  Emit.End
                case (_, Emit.End) =>
                  c.state = End
                  Emit.End
                case (Emit.Wait, Emit.Wait) =>
                  Emit.Wait
                case (Emit.Wait, Emit.Value(r)) =>
                  c.state = CacheRight(r)
                  Emit.Wait
                case (Emit.Value(l), Emit.Wait) =>
                  c.state = CacheLeft(l)
                  Emit.Wait
                case (Emit.Value(l), Emit.Value(r)) =>
                  Emit.Value((l, r))
            case CacheRight(r) =>
              left.next() match
                case Emit.End =>
                  c.state = End
                  Emit.End
                case Emit.Wait     => Emit.Wait
                case Emit.Value(l) =>
                  c.state = Continue
                  Emit.Value((l, r))
            case CacheLeft(l) =>
              right.next() match
                case Emit.End =>
                  c.state = End
                  Emit.End
                case Emit.Wait     => Emit.Wait
                case Emit.Value(r) =>
                  c.state = Continue
                  Emit.Value((l, r))
        case c @ Compiled.Take(source, count) =>
          if count == 0 then Emit.End
          else
            source.next() match
              case Emit.Value(get) =>
                c.count = count - 1
                Emit.Value(get)
              case Emit.Wait =>
                // Waits don't change the count
                Emit.Wait
              case Emit.End =>
                c.count = 0
                Emit.End
        case Compiled.FromIterator(it) =>
          if it.hasNext then Emit.Value(it.next)
          else Emit.End
        case c @ Compiled.FromSeq(seq, idx) =>
          if idx == seq.size then Emit.End
          else
            val elt = seq(idx)
            c.idx = idx + 1
            Emit.Value(elt)

  object Compiled:
    def fromStream[A](stream: Stream[A]): Compiled[A] =
      stream match
        case Stream.Filter(source, pred) =>
          Filter(fromStream(source), pred)
        case Stream.Map(source, f) =>
          Map(fromStream(source), f)
        case Stream.Merge(left, right) =>
          Merge(
            fromStream(left),
            fromStream(right),
            MergeDirection.PullLeft
          )
        case Stream.Product(left, right) =>
          Product(
            fromStream(left),
            fromStream(right),
            ProductState.Continue
          )
        case Stream.Take(source, count) =>
          Take(fromStream(source), count)
        case Stream.FromIterator(it) => FromIterator(it)
        case Stream.FromSeq(seq)     => FromSeq(seq)

  def fromIterator[A](it: Iterator[A]): Stream[A] =
    Stream.FromIterator(it)

  def fromSeq[A](seq: Seq[A]): Stream[A] =
    Stream.FromSeq(seq)
```

Now our example program works as expected
    
```scala mdoc
Stream.fromIterator(Iterator.continually(1))
  .filter(_ != 1)
  .merge(Stream.fromSeq(Seq(2)))
  .take(1)
  .toSeq
```
]

This section and the previous one have shown the importance of precisely defining semantics.
Precise definitions in turn require terminology.
To talk about `Stream` semantics we introduced the concepts of demand or pulls, upstreams, and downstreams.
In many problems developing this kind of semantic model is the most important step,
and here that the domain-specific knowledge is found.
Once we have the model, the programming strategies help us translate it to code.
