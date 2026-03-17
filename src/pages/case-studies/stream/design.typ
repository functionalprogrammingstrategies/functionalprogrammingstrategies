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

Our next strategy is the interpreter. Is this appropriate for our reactive `Stream`? An interpreter means a separation between description and action, which in this context means we describe the structure of the stream processing graph before we run it. This seems like a good thing in our situation: it means the graph is fully constructed before it starts running, and therefore won't lose data because the it isn't complete when the first data arrives.

The implication of using the interpreter strategy is we need to think about the elements of our algebra: the introduction forms, combinators, and elimination forms. We've already addressed combinators, but we haven't yet touched on the other two. It's time to change that, starting with the elimination forms.

Remember "elimination forms" is just fancy words for how we run the interpreter. We earlier said that our `Stream` is dual to a standard sequential data structure. We know that there are two universal eliminators for structures like `List`: the left and right folds. So these are candidates for our interpreter. The right fold starts from the end of the data, which when our data is arriving over time means we need to either store it all in memory or find a time machine (not to mention that data could be infinite, and hence never end). These all suggest that `foldRigth` is not appropriate. However, `foldLeft` has none of these issues. Let's use it. Our interface is now

```scala mdoc:silent:reset
trait Stream[A]:
  // Combinators
  def map[B](f: A => B): Stream[B]
  def product[B](that: Stream[B]): Stream[(A, B)]

  // Eliminator
  def foldLeft[B](zero: B)(f: (B, A) => B): B
```

We now need some introduction forms, or constructors are they are more often known. This gets interesting because it's here that we connect our `Stream` to the outside: the network sockets and keyboard events that produce the raw input we'll work with. However we run into a different limitation: integrating with the outside world is complex, and that complexity is not essential to what we are trying to demonstrate in this case study. So for now, we going to use a single constructor that converts an `Iterator` to a `Stream`. We're choosing `Iterator` because it has state, and so will illustrate some of the problems that the real world brings.

Here's the final interface:

```scala
trait Stream[A]:
  // Combinators
  def map[B](f: A => B): Stream[B]
  def product[B](that: Stream[B]): Stream[(A, B)]

  // Eliminator
  def foldLeft[B](zero: B)(f: (B, A) => B): B
object Stream:
  // Constructor
  def fromIterator[A](it: Iterator[A]): Stream[A]
```

We've sketched out a basic interface, and we've used the programming strategies to help us do so.

Contextual abstraction
