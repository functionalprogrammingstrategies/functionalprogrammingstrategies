#import "../../stdlib.typ": exercise, solution
== Implementing `Stream`

In the previous section we sketched out the interface for our `Stream` type:

```scala mdoc:silent
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

In this section we'll implement this interface.

In @sec:interpreters:reification we met reification, a basic strategy for implementing interpreters.
There's no reason not to try this, so let's reify the interface and see where it ends up.
This is a straightforward process, covered in detail in @sec:interpreters, so I'll just skip to the reified code.
Note the interpreter method, `foldLeft`, remains unimplemented.

```scala mdoc:silent:reset
enum Stream[A]:
  case Map[A, B](source: Stream[A], f: A => B) extends Stream[B]
  case Product[A, B](left: Stream[A],  right: Stream[B]) extends Stream[(A, B)]
  case FromIterator(it: Iterator[A])

  def map[B](f: A => B): Stream[B] =
    Map(this, f)

  def product[B](that: Stream[B]) =
    Product(this, that)

  def foldLeft[B](zero: B)(f: (B, A) => B): B = ???

object Stream:
  def fromIterator[A](it: Iterator[A]): Stream[A] =
    Stream.FromIterator(it)
```

Our next step is to implement the interpreter, `foldLeft`.

#exercise[Basic Interpreter]

Try implementing the interpreter. For this we can use structural recursion, introduced in @sec:adt:structural.

#solution[
    You'll find that you cannot correctly implement `product`, at least without extraordinary difficulty.
]

For `product` we need to be able to get elements one at a time from the left and right streams, so that we can tuple them together.
We cannot implement `product` in terms of `foldLeft`, without extreme contortions, because `foldLeft` doesn't give us enough flexibility with control flow.
This suggests a more primitive method like

```scala
def next(): Option[A]
```

where the result is an `Option` because there may not be any more elements available.

Before we implement this, let's think about how we could have foreseen the need for this method.
When we discussed `foldLeft` we hinted that there could be some issues with it.
Now we know exactly what problem it brings.


#exercise[Better Interpreter]

Implement `next` and then implement `foldLeft` using it.


#solution[

    Here's my first attempt at a solution. Do you see the problem?
    
```scala mdoc:silent:reset
import cats.syntax.all.*

enum Stream[A]:
  case Map[A, B](source: Stream[A], f: A => B) extends Stream[B]
  case Product[A, B](left: Stream[A],  right: Stream[B]) extends Stream[(A, B)]
  case FromIterator(it: Iterator[A])

  def map[B](f: A => B): Stream[B] =
    Map(this, f)

  def product[B](that: Stream[B]) =
    Product(this, that)

  def next(): Option[A] =
    this match
      case Map(source, f) => source.next().map(f)
      case Product(left, right) => (left.next(), right.next()).tupled
      case FromIterator(it) => Some(it.next)

  def foldLeft[B](zero: B)(f: (B, A) => B): B =
    this.next() match
      case Some(v) => foldLeft(f(zero, v))(f)
      case None => zero

object Stream:
  def fromIterator[A](it: Iterator[A]): Stream[A] =
    Stream.FromIterator(it)
```

    If haven't checked if the `Iterator` has any elements. This method's result type doesn't reflect that it can fail. If it returned, say, an `Option` then this would be obvious, and our programming strategies would lead us to the correct solution. This isn't done because an `Option` requires memory allocation, and this is an interface that is deemed to need optimization. However, it does show us the downside of imperative programming, and the illustrate how we can easily avoid these problems at the cost of some performance. Here's the corrected code.

```scala mdoc:silent:reset
import cats.syntax.all.*

enum Stream[A]:
  case Map[A, B](source: Stream[A], f: A => B) extends Stream[B]
  case Product[A, B](left: Stream[A],  right: Stream[B]) extends Stream[(A, B)]
  case FromIterator(it: Iterator[A])

  def map[B](f: A => B): Stream[B] =
    Map(this, f)

  def product[B](that: Stream[B]) =
    Product(this, that)

  def next(): Option[A] =
    this match
      case Map(source, f) => source.next().map(f)
      case Product(left, right) => (left.next(), right.next()).tupled
      case FromIterator(it) => if it.hasNext then Some(it.next) else None

  def foldLeft[B](zero: B)(f: (B, A) => B): B =
    this.next() match
      case Some(v) => foldLeft(f(zero, v))(f)
      case None => zero

object Stream:
  def fromIterator[A](it: Iterator[A]): Stream[A] =
    Stream.FromIterator(it)
```
]

With a working interpreter we can define some programs

```scala mdoc:silent
val s1 = Stream.fromIterator(Iterator(1, 2, 3))
val s2 = Stream.fromIterator(Iterator(4, 5, 6))
val s3 = s1.product(s2)
```

and run them

```scala mdoc
Seq(s3.next(), s3.next(), s3.next())
```
