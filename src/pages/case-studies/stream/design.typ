== Designing with Strategies

Let's start with the four basic strategies introduced in @sec:part:foundations:

- data and codata;
- interpreters; and
- contextual abstraction.

How do they apply to reactive programming? Let's start with data. We know that data and codata are duals, so we're probably only going to use one of them. Codata is infinite, which seems to be a good fit the type of problems that reactive programming solves: working with unbounded streams of data.

If we're creating a codata abstraction, that means we need to focus on destructors, or to put it in possibly more familiar terms, the interface we provide. We can find inspiration from a number, but a strategy that I find widely applicable is to consider if any of common type classes suggest methods. The common type classes were discovered because they named interfaces found in many different situations; we can reverse that process and ask if they apply to ours.

We'll first consider `Functor`, the principle method being `map`. This makes a lot of sense for reactive programming. We have a stream of data arriving, and we want to transform that into some other type. So we'll definitely want `map`.

Moving on to `Applicative`, the main method is `product`. What does this mean for a reactive program? The signature of `product` is

```scala
def product[A, B](fa: F[A], fb: F[B]): F[(A, B)]
```

Let's replace `F` with `Stream` to make it clearer we're dealing with streams of data.

```scala
def product[A, B](fa: Stream[A], fb: Stream[B]): Stream[(A, B)]
```

Now `product` is telling us it takes two streams and returns `Stream[(A, B)]`. So it's combining two streams. That sounds useful, so it's going in.

What about `Monad`. Does

```scala
def flatMap[A, B](fa: Stream[A], f: A => Stream[B]): Stream[B]
```

make sense? This is not so clear. What `flatMap` gives us is a dynamic switch between streams. Each element from `fa` is inspected by `f`, which can choose a `Stream[B]` according to that element. It could be useful, but it also sounds a bit complicated to get started with, so let's leave it aside for now.

Our initial interface thus looks like

```scala mdoc:silent
trait Stream[A]:
  def map[B](f: A => B): Stream[B]
  def product[B](that: Stream[B]): Stream[(A, B)]
```

We're going to move on, but before doing so I want to talk about other places we can find inspiration. The first is prior work. Knowing that reactive systems already exist, we could look up how they work and the APIs they provide. In @sec:codata-structural we created another kind of infinite stream, which feels quite similar to what we're doing here. This could be another source of inspiration. We can also reason our way to other similar systems. We can think of a stream as holding data arranged in sequence by time, from the first piece of data in the past to the last piece of data that will arrive in the future. From Einstein we know that space is dual to time, so what is the dual of a stream? It's data arranged in sequence in space---that is, the computer's memory. This is simply any ordered data structure, such as Scala's `Seq`. Therefore we can look at their APIs for inspiration. We'll keep these ideas in mind when we want to expand the API.

