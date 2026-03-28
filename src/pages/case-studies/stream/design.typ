== Designing with Strategies

In this section we'll take a first principles approaches to design, systematically applying strategies to create the initial interface we'll implement.
Before doing so, however, I want to mention another strategy that is extremely powerful but often neglected: utiliziing *prior work*.

It's very rare to undertake a truly novel problem.
Researching prior work provides a shortcut both to design and implementation, and can help us avoid many problems.
This is the reason that most chapters end with a short survey of relevant literature:
I want to show that the ideas in this book build on existing work, and help you dive into the literature if this is not something you're accustomed to doing.
Researching prior work is always my first approach to any design problem, though we won't use it here as we're trying to illustrate the application of the other strategies.

Let's start with some fundamental principles that will guide our design. The core of reactive programming is to react to data as it becomes available. This means we're not creating a kind of data structure, because that implies accumulating data in memory. The user may choose to hold on to past data, but we shouldn't mandate that memory usage grows with the amount of data processed. This is particularly important because in many situations the data is effectively unbounded. For example, a user interface can easily receive millions of mouse events in a single session.

If we're not creating data structures, we should consider their dual, programs. This gives us a better model: we can build a way of specifying a program, a domain specific language (DSL), that can be repeatably applied to data. These programs may contain some state, so they can remember past interactions, but this is something for the program author to decide, not our DSL. 

We have enough principles to get started. Let's now turn to the basic strategies introduced in @sec:part:foundations:

- data (@sec:adt) and codata (@sec:codata);
- interpreters (@sec:interpreters); and
- contextual abstraction (@sec:type-classes).

How can we apply them to reactive programming? Let's start from the top. We've already decided we're building a DSL for programs, not a data structure, and this suggests we should use codata. We could arrive at the same conclusion by considering we want to work with unbounded streams of data. To make the following discussion clearer, let's give the name `Stream` the type we're creating. Don't confuse this with the type of the same name we saw in @sec:codata-structural. They are related but ultimately different.

Our next strategy is the interpreter. Is this appropriate for our reactive `Stream`? Yes, if a `Stream` is a program then it must have an interpreter. We can also consider this decision from a different angle. An interpreter means a separation between description and action, which in this context means we describe the structure of the stream processing graph before we run it. This seems like a good thing: it means the graph is fully constructed before it starts running, and therefore won't lose data because the graph isn't complete when the first data arrives.

The implication of using the interpreter strategy is we need to think about the elements of our algebra: the introduction forms, combinators, and elimination forms. We'll make a mental note to come back to this and move on to the next strategy.

It's not clear how the next strategy, contextual abstraction, applies to `Stream`. However, there is a way to leverage the common type classes, introduced in @sec:part:type-classes, to help design the combinators of our algebra.
These type classes are useful because they are found in so many different situations.
We can reverse that process and ask if they apply to ours.

We'll first consider `Functor`, the principle method being `map`. This makes a lot of sense for reactive programming. We have a stream of data arriving, and we want to transform that into some other type. So we'll definitely want `map`.

Moving on to `Applicative`, the main method is `product`. What does this mean for a reactive program? The signature of `product` is

```scala
def product[A, B](fa: F[A], fb: F[B]): F[(A, B)]
```

Let's replace `F` with `Stream` to make it clearer we're dealing with streams of data.

```scala
def product[A, B](fa: Stream[A], fb: Stream[B]): Stream[(A, B)]
```

Now `product` is telling us it takes two streams and returns `Stream[(A, B)]`, so it's combining two streams. That sounds useful: imagine combining a stream of mouse movements and mouse clicks to produce a stream of click positions, or a stream of CPU load and error messages to allow analysis of system performance under load. Let's add it.

What about `Monad`. Does

```scala
def flatMap[A, B](fa: Stream[A], f: A => Stream[B]): Stream[B]
```

make sense? This is not so clear. What `flatMap` gives us is a dynamic switch between streams. Each element from `fa` is inspected by `f`, which can choose a `Stream[B]` according to that element. This could be useful, say for a user interface where clicking on a tab makes a different interface visible. However it does feel like it's more complex that the other methods we've seen so far. At this point we need just enough to get started, so let's leave it aside for now.

Our initial interface thus looks like

```scala mdoc:silent
trait Stream[A]:
  def map[B](f: A => B): Stream[B]
  def product[B](that: Stream[B]): Stream[(A, B)]
```

We've made progress on our combinators. Let's switch to elimination forms. Remember, this is just a fancy term for how we run the interpreter.
One way to come up with an interface is to leverage duality.
We earlier said that our `Stream` is a type of program, dual to data.
What exactly would the dual be?
If we think of a `Stream` as a program working on data ordered by time, then we might ask what is data ordered by space?#footnote[
    If we like, we can connect this to special relativity, which says we can mix space and time.
    It's not a true duality, as I understand it, but a relationship that feels very close to one.
]
A sequential data structure, like `List`, is the answer.
We know that there are two universal eliminators for structures like `List`: the left and right folds. So these are candidates for our interpreter. The right fold starts from the end of the data, which when our data is arriving over time means we need to either store it all in memory or find a time machine (not to mention that data could be infinite, and hence never end). These all suggest that `foldRight` is not appropriate. However, `foldLeft` has none of these issues. You might feel some unease with `foldLeft`. For example, it won't return a value until the stream ends, which feels like it could be a problem in some situations. Again, we just need enough to get started, so we'll add to the interface and see how it works out in practice.

```scala mdoc:silent:reset
trait Stream[A]:
  // Combinators
  def map[B](f: A => B): Stream[B]
  def product[B](that: Stream[B]): Stream[(A, B)]

  // Eliminator
  def foldLeft[B](zero: B)(f: (B, A) => B): B
```

We now need some introduction forms, or constructors as they are more often known. This gets interesting because it's here that we connect our `Stream` to the outside world: the network sockets and keyboard events that produce the raw input we'll work with. However we run into a different limitation: integrating with the outside world is complex, and that complexity is counter to the focus on essentials that we want in a case study. So, for now we are going to use a single constructor that converts an `Iterator` to a `Stream`. We're choosing `Iterator` because it has internal state, and so will illustrate some of the issues that come with interacting with a stateful world.

Here's the final interface:

```scala mdoc:silent:reset
trait Stream[A]:
  // Combinators
  def map[B](f: A => B): Stream[B]
  def product[B](that: Stream[B]): Stream[(A, B)]

  // Eliminator
  def foldLeft[B](zero: B)(f: (B, A) => B): B
object Stream:
  // Constructor
  def fromIterator[A](it: Iterator[A]): Stream[A] =
    ???
```

In a case study we can take a straight path from problem to solution.
In this section we've done just that.
In a real system the path will involve many more dead ends.
I find the design strategies a useful scaffold for thinking,
even if I cannot as immediately see how to apply them as shown here.
