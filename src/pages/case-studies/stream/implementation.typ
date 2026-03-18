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

In @sec:interpreters:reification we met reification, a basic strategy for implementing interpreters.
There's no reason not to try this, so let's reify the interface and see where it ends up.
This is a straightforward process, covered in detail in @sec:interpreters, so I'll just skip to the reified code.
Note the interpreter method, `foldLeft`, remains unimplemented.

```scala mdoc:silent
enum Stream[A]:
  case Map[A, B](source: Stream[A], f: A => B) extends Stream[B]
  case Product[A, B](left: Stream[A],  right: Stream[B]) extends Stream[(A, B)]
  case FromIterator(it: Iterator[A])

  def foldLeft[B](zero: B)(f: (B, A) => B): B = ???
object Stream:
  def fromIterator[A](it: Iterator[A]): Stream[A] =
    Stream.FromIterator(it)
```

Our next step is to implement the interpreter, `foldLeft`. For this we can apply structural recursion, introduced in @sec:adt:structural. Try this yourself now.

You'll find that you can't implement `product`. What's the problem here?
To implement `product` we need to get elements one at a time from the left and right streams.
This suggests a method like

```scala
def next: Option[A]
```

where the result is an `Option` because there may not be any more data available.

Before we go ahead and implement this, let's think about how we could have foreseen the need for this method.
When we discussed `foldLeft` we hinted that there could be some issues with it.

