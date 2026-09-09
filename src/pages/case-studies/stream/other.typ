== Other Approaches
<sec:case-study:reactive:other>

So far we've stuck to the pull-based model, which fell out of using the reification strategy. It's natural to wonder what its dual, a *push-based* approach, would look like.
We'll do that here, as well as more briefly considering *incremental computing*, a programming model closely related to reactive programming.


=== Push-Based Streams

We've been working with a data interpreter, the core being the dispatch over the
`Compiled` and `Emit` algebraic data types. This followed from a somewhat
arbitrary decision to use reification. We might wonder what the codata approach
would look like. Let's try it and see!

The final interpreter loop for the data `Stream` was

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

We'll dualize this to arrive at a codata implementation
starting with `Emit`, reproduced below.

```scala mdoc:silent
enum Emit[+A]:
  // The pull produced a value
  case Value(get: A)
  // There is no value available now, but there may be in the future
  case Wait
  // The stream has ended and no values will ever be available
  case End
```

Dualizing `Emit` is straightforward, giving us the following interface:

```scala mdoc:reset:silent
trait Emit[A]:
  def value(get: A): Unit
  def wait: Unit
  def end: Unit
```

The codata version of `Emit` replaces constructors with methods that indicate the availability of data.
This inverts the control flow: instead of returning a new instance of `Emit` we now call a method on an existing instance.
In other words, we have gone form direct style to continuation-passing style.
This in turn implies that we must write our interpreter loop in continuation-passing style.
The signature of `next` becomes

```scala
def next(cont: Emit[A]): Unit
```

accepting a continuation to call.

... implementation detail here ...

... changes to loop ...

In `loop` we bridge between continuation-passing and direct style by (eventually) storing a value in the mutable variable `result`.

There are a few interesting things to note about the implementation.

This continuation passing approach gives us a hybrid push/pull model.
We recurse down the `Compiled` data structure, constructing a chain of continuations.
This is equivalent to the recursion we did in the data interpreter,
and the construction of the continuation represents the demand for data.
We then push a value up the continuation chain.

Our implementation recreates the continuations on each call to `next`.
Constructing the continuations once would be more efficient, and give us a purely push-based implementation.
This raises its own set of issues.

The pull-based model only pulls a new value when the entire `Stream` is ready to process it.
To add the same to the push-based model we must introduce *back pressure*,
a way for downstream elements to signal to their upstream sources that they are ready to handle more data.
The need arises even without concurrency.
For example, `merge` needs to indicate which of its sources can produce data at any point in time.
If the left source has produced a value but the right is awaiting, the left should not produce another value until the right has done so.

There is also the problem of *glitches*, which are transient incorrect values.
... describe glitches here ...
Topological order instead of the naive depth-first order.

The push-based model makes it easy to implement fan-out, an advantage over the pull-based model.
Fan-in, however, is harder to implement.
This is a fundamental difference between the two, and relates to the difference in control flow.
The pull model locates control at the sink, which propagates it to the upstream tree.
Any operation that involves a subtree reachable from the sink follows the natural control flow,
and is (relatively) straightforward to implement.
Fan-in is an example of such an operation.
Fan-out, however, requires interaction between control located
The reverse is true for the push model: control is located at the source and propagates to the downstream tree.
This makes fan-out simple, but fan-in complicated.

ReactiveX
