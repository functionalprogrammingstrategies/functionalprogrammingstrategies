== Implementing `Stream`

In the previous section we sketched out the interface for our `Stream` type:

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

In this section we'll implement this interface.

In @sec:interpreters:reification we met reification, the basic strategy for implementing interpreters.
There's no reason not to try this, so let's reify the interface and see where it ends up.
This is a straightforward process, covered in detail in @sec:interpreters, so I'll just jump to the completed code.

```scala mdoc:silent
enum Stream[A]:
  case Map[A, B](source: Stream[A], f: A => B) extends Stream[B]
  case Product[A, B](left: Stream[A],  right: Stream[B]) extends Stream[(A, B)]
  case FromIterator(it: Iterator[A])

  def foldLeft[B](zero: B)(f: (B, A) => B): B
object Stream
  def fromIterator[A](it: Iterator[A]): Stream[A] =
    Stream.FromIterator(it)
```

Our next step is to implement the interpreter, `foldLeft`. For this we can apply structural recursion, introduced in @sec:adt:structural. A bit of following the types leads us to[#sym.dots.h]some problems: we cannot implement `product`, and what we can implement will operate on all the data at once, not on the data an element at a time.
