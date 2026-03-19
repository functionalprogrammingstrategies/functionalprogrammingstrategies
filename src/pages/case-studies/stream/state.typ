#import "../../stdlib.typ": exercise, solution
== Handling State

As our next feature we'll add a constructor to create a `Stream` from a `Seq`. This will get us to think about semantics and show how we can handle state within an interpreter. This features seems quite simple. We want a constructor

```scala
def fromSeq[A](seq: Seq[A]): Stream[A]
```


#exercise[Sequence Constructor]

Implement the `fromSeq` constructor.


#solution[
    Implementing this constructor should raise an interesting problem: how do we track the current position within the `Seq`?
    We need some state that updates with each call to `next`.
    Converting the `Seq` to an `Iterator` is an easy way to handle this, as the `Iterator` maintains the current position as internal state.
    The position needs to persist across calls to `next`, so I put the conversion in the constructor.

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

  def fromSeq[A](seq: Seq[A]): Stream[A] =
    fromIterator(seq.iterator)
```
]

Handling state by converting the `Seq` to an `Iterator` seems like a reasonable approach. If we define a stream like

```scala mdoc:silent
val s = Stream.fromSeq(Seq(1, 2, 3))
```

we seem to get the correct result when we run it.

```scala mdoc
Seq(s.next(), s.next(), s.next())
```

However, run the stream again and we get some odd results.

```scala mdoc
// Should be Seq(Some(1), Some(2), Some(3))
s.foldLeft(Seq.empty)(_ :+ _)
```

What's going on here?

My choice to convert the `Seq` to an `Iterator` at the point where the `Stream` is constructed means the state inside the `Iterator` is scoped to the entire `Stream`, not just one particular run of the interpreter. This is incorrect. The state should only be visible inside the interpreter#footnote[
    Where we explicitly construct a `Stream` from a stateful `Iterator`, using `fromIterator`, is different. Here the state is an unavoidable part of the external world, not part of the interpreter.
].
