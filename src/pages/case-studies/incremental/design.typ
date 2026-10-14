== Designing Incremental Computing

We're going to design our incremental computing by applying strategies, just as we did in @sec:case-study:reactive:design. I want to once again note that reading the literature is an very appropriate strategy to use here---see the literature review in @sec:case-study:incremental:conclusions---but we're going to take the harder route and build it from scratch.

We'll start with the API.
Incremental programming is very similar to reactive programming, so we can use a similar API.
The methods that don't carry across to incremental computing are ones that work with some notion of time.
Examples are methods that throttle changes or apply an operation over a time window.
We didn't implement any of these, so we can carry across the API with little change.
Following Javascript naming conventions, we'll call our basic type `Signal` and our initial API will be

```scala mdoc:silent
trait Signal[A]:
  def get: A

  def map[B](f: A => B): Signal[B] =

  def product[B](that: Signal[B]): Signal[(A, B)] =
```

Notice the one major change from `Stream`: the interpreter is `get`, which simply returns the current value of the `Signal`, instead of `foldLeft`. This is because `Signals` don't have a notion of time, and so don't support folding over the history of values.

We don't have any constructors. `State`, `set`, and `update`.

We could reify, but we saw an extensive case study using this approach in @sec:case-study:reactive. Instead we'll take a codata approach.

```scala mdoc:silent
trait Signal[A]:
  self =>

  def get: A

  def map[B](f: A => B): Signal[B] =
    new Signal[B]:
      def get: B = f(self.get)

  def product[B](that: Signal[B]): Signal[(A, B)] =
    new Signal[(A, B)]:
      def get: (A, B) = (self.get, that.get)

class State[A](initialValue: A) extends Signal[A]:
  private var value: A = initialValue

  def get: A = value

  def set(newValue: A): Unit =
    value = newValue

  def update(f: A => A): Unit =
    value = f(value)

object Signal:
  def apply[A](value: A): State[A] =
    State(value)
```

We can check our implementation with some simple examples, such as adding two numbers.

```scala mdoc:silent
val a = Signal(1)
val b = Signal(2)
val c = a.product(b)
val d = c.map((a, b) => a + b)
val e = c.map((a, b) => a * b)
```

It calculates the correct value and recalcuates when a dependency changes.

```scala mdoc
d.get
e.get

a.set(5)

d.get
e.get
```

So, are we done? Let's think about semantics. Dependencies update when they are observed by calling `get`. In other words, we have lazy semantis. This seems reasonable, as we only recompute what we need. Or do we? We only *initiate* recomputation when we need a value, but we recompute far more than necessary, evaluating the entire dependency tree even if part of it hasn't changed.

Visualization.

Dependent (downstream) / dependee (upstream)

The dual, eager evaluation, seems a natural approach to try but this just pushes the problem around. Now we recompute whenever a dependency changes. This avoids

we do too much work: recomputing the entire tree when we could stop short. What's the alternative. The dual, *eager* seems natural. Recompute whenever a dependency changes.

Visualisation. Still does too much work. Recompute values that are never needed. What if we don't need a dependent?

What's the alternative? Push-pull or eager-lazy.

What about: eagerly mark what needs recomputing, but only recompute when needed. Eager / lazy or push-pull following reactive terminology. A classic space-time tradeoff: use more memory to avoid computation.

How do we implement? Pull demands flows from downstream to upstream and results flow upstream to downstream. Push inverts this. CPS. Listeners.

Critically relies on single threaded assumption.
