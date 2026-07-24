== Other Approaches
<sec:case-study:reactive:other>

So far we've stuck to the pull-based model, which we arriving at by deciding to use the reification strategy. It's natural to wonder what its dual, a *push-based* approach, would look like.
We'll do that here, as well as more briefly considering *incremental computing*, a programming model closely related to reactive programming.


=== Push-Based Streams

We've been working with a data interpreter, the core being the dispatch loop in `next` over the `Emit` algebraic data type.
This was a somewhat arbitrary decision to use reification, which naturally leads to a data approach.
We might want what the codata approach would look like.
Let's try it and see!

We'll start with `Emit`, reproduced below.

```scala mdoc:silent
enum Emit[+A]:
  // The pull produced a value
  case Value(get: A)
  // There is no value available now, but there may be in the future
  case Wait
  // The stream has ended and no values will ever be available
  case End
```

Dualizing it is straightforward, giving us the following interface:

```scala mdoc:reset:silent
trait Emit[A]:
  def value(get: A): Unit
  def wait: Unit
  def end: Unit
```

The codata version of `Emit` has methods to call to indicate the availability of data.
Switching from returniing values of `Emit` to calling methods on it means our interpreter is now written in continuation-passing style.
This in turn means the signature of `next` becomes

```scala
def next(cont: Emit[A]): Unit
```
