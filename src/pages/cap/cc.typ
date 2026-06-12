== Capture Checking

Capture checking is one of the parts missing from the capability-passing story we've told so far.
The core idea is to prevent capabilities being used outside the scope where they are valid.
This is done by tracking, in types, values that cannot be captured;
that is stored in a closure or variable, or otherwise used in a way that could leak the capability outside the scope.

Imagine we have a capability that allows us to raise an error, similar to an exception.
Let's call it `Raise` and assume it has a method `raise` that takes the value we use to indicate the error.
Usage might look something like

```scala
val example =
  (ctx: Raise[String]) ?=> if true then ctx.raise("This is an error") else 0
```

We naturally want to ensure we handle all errors.
The instance of `Raise` we provide should catch all the errors,
and we cannot run `example` without providing such an instance of `Raise`.
So it seems we're ok.
Concretely, let's imagine there is an instance `Raise.either` that runs a contextful function that could fail,
and returns an `Either` containing the success or failure value.

```scala
val result: Either[String, Int] =
  Raise.either(example)
```

When we run `example` with `Raise.either` we ensure we catch all the errors with in `example`.
Or do we?
There is a way that `example` could circumvent this.
Imagine the following implementation `example`.

```scala
val example =
  (ctx: Raise[String]) ?=>
    () => ctx.raise("Surprise!")
```

It returns a closure that holds on to the `Raise` instance.
We could then apply this closure to raise an error outside the scope where we're handling errors.

```scala
Raise.either(example) match
  case Left(err) => ???
  case Right(closure) =>
    closure() // raise an error outside the handler!
```

We say that the closure has captured a reference to the capability.
This is exactly what capture checking prevents, because, as we've seen,
capturing capabilities can lead to errors.

Example: capturing the layout capability and using it during the render phase when it's not valid (dynamically adding components.)
Explain how capture checking can solve this.

Fundamentally, capture checking extends the type system to reason about resources.
We can view this as another approach to indexed codata, which we met in @sec:indexed-types:codata.
The core idea is the same: we cannot call certain methods unless certain conditions are met.
The details are, however, different.
Indexed codata restricts which methods are callable based on type-level state reflecting the allowed protocol.
Cannot stop capturing / escape.
Capture checking restricts where values can flow.
Cannot express protocol: this method only after that method.

A central idea in capability-passing: capabilities should be lexically scoped, as this is far easier to reason about. Capture checking enforces this.
