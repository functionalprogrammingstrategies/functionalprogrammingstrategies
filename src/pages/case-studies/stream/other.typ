== Other Approaches
<sec:case-study:reactive:other>

So far we've stuck to the pull-based model, which fell out of using the reification strategy. It's natural to wonder what its dual, a *push-based* approach, would look like.
We'll do that here, as well as more briefly considering *incremental computing*, a programming model closely related to reactive programming.


=== Push-Based Streams

We've been working with a data interpreter, the core being the dispatch over the `Compiled` and `Emit` algebraic data types.
This followed from a somewhat arbitrary decision to use reification.
We might wonder what the codata approach would look like.
Let's try it and see!

Here's the final interpreter loop we arrived at:

```scala
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
```

Let's start with `Emit`, reproduced below.

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
This alters the control flow: instead of returning values of `Emit` we must now call methods on it.
This in turn implies that we must write our interpreter loop in continuation-passing style.
The signature of `next` becomes

```scala
def next(cont: Emit[A]): Unit
```

accepting a continuation to call.
