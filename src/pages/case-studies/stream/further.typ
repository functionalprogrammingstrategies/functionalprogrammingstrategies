== Further Enhancements

There are many more additions we could add to `Stream`.
In this section we'll sketch out some directions you could take `Stream`
to develop it further.
We're not going to walk through the implementation of any more features,
however, as we've already illustrated all the ideas we wanted to address in this case study.


=== `flatMap`

In our original design we decided that `flatMap` could be useful,
but sounded a bit complicated for our initial implementation.

Adding `flatMap` is an obvious next step.
This makes `Stream` a monad.
Type class coherence demands that `product` should now be implemented in terms of `flatMap`,
which gives it quite different semantics.
The `product` we originally implemented is still useful, and we should rename the method; `zip` would be the idiomatic name.


=== Concurrency

Concurrency is a natural extension.
There are at least two ways that we could support concurrency:
via a concurrent pipeline of transformations,
and by concurrent merging of streams.

Concurrent transformations could be built upon a concurrent map operation like

```scala
def concurrentMap[B](maxConcurrency: Int)(f: A => B)
```

where `maxConcurrency` specifies the maximum number of concurrent applications of `f` that can be in-flight at any one time.

Notice that this breaks the principle of matching upstream and downstream demand one-to-one;
a single downstream pull can result in `maxConcurrency` upstream pulls.
It also means we can store up to `maxConcurrency` elements in memory awaiting downstream demand.
However, this is explicit in the code, as the user specifies `maxConcurrency`, and demand and memory use are still bounded.

We might also want to allow the user to specify a thread pool to be used.
One way to do this is by passing an `ExecutionContext`.

```scala
def concurrentMap[B](maxConcurrency: Int)(f: A => B)(using ec: ExecutionContext)
```

Concurrent merging could take the form of a `merge` variant that doesn't strictly alternate between left- and right-hand upstreams, but instead returns a value from whichever emits one first. This again doesn't match demand (a downstream pull can result in two upstream pulls) and results in caching a value in memory in the case where both upstreams emit values before two pulls from the downstream.

Another approach to concurrent merging is to race two streams, returning the value from the `Stream` that emits a value first, and discarding the value, if any, emitted by the other `Stream`.


=== Fan-In and Fan-Out

*Fan-in* is when multiple upstreams join into a single downstream. We already support fan-in with `merge`. What we don't support is *fan-out*, sending one upstream to multiple downstreams. Think about the following code:

```scala
val upstream = Stream.fromIterator(Iterator(1, 2, 3))

upstream.merge(upstream.map(s => s * 2)).toSeq
```

This is an (incorrect) attempt to express fan-out with the available combinators.
Think about why this doesn't express fan-in; it's fairly subtle issue if you're not used to thinking about the description / action distinction #footnote[
    We can reason about this using substitution.

    Starting with

    ```scala
    upstream.merge(upstream)
    ```

    we can substitute `upstream` to get

    ```scala
    Stream.fromIterator(...).merge(Stream.fromIterator(...))
    ```

    whichs shows us that `upstream` is duplicated.
    A correct fan-out would have `upstream` occur only once.

    This occurs because `upstream` is a description,
    so we're just repeating the description of what we want to happen
    when we use `upstream` twice.

    This is completely the correct semantics,
    but it may be a bit surprising if you think of `Stream` as an action, not a description.
].

We need a specific combinator to express fan-out.


== Optimization


== Documentation

It may feel odd to mention documentation as an enhancement, but in my experience too many libraries have inadequate documentation.

We've developed a robust mental model in writing `Stream`, and its important we communicate that model to users. This type of documentation, in particular, is what I find missing in many projects. 
