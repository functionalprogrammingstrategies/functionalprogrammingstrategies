#import "../../stdlib.typ": exercise, solution
== Handling State

Our next feature will be a constructor to create a `Stream` from a `Seq`. This will get us to think more deeply about semantics and show how we can handle state within an interpreter.

This features seems quite simple. We want a constructor

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
s.foldLeft(Seq.empty)(_ :+ _)
// Should be Seq(Some(1), Some(2), Some(3))
```

What's going on here?

My choice to convert the `Seq` to an `Iterator` at the point where the `Stream` is constructed means the state inside the `Iterator` is scoped to the entire `Stream`, not just one particular run of the interpreter. This is incorrect. The state should only be visible inside the interpreter#footnote[
    Where we explicitly construct a `Stream` from a stateful `Iterator`, using `fromIterator`, is different. Here the state is an unavoidable part of the external world, not part of the interpreter.
].

Let's examine this in more detail. The core of the interpreter strategy is the separation of the code into the program, which describes what we want to happen, and the interpreter, which carries out the commands in the program. This state, the current index of the sequence, is part of a particular run on the interpreter, not the program. One implication of this is that

```scala
Seq(s.next(), s.next(), s.next())
```

should produce

```scala
Seq(Some(1), Some(1), Some(1))
```

as each call to `next` is a new invocation of the interpreter. The actual output we saw is incorrect, because the state carries across multiple runs of the interpreter. Another implication is that we probably should not expose `next` to the user. It never really makes sense to run the `Stream` only once, and the semantics are confusing.

We still have the fundamental problem: how exactly are we going to create state that only lives in the interpreter? In a tree walking interpreter, my favourite way to handle this is to compile the program into a stateful abstract syntax tree. The state is nicely isolated where it's needed and interpretation is still a simple structural recursion. The code is below.

```scala mdoc:silent:reset
import cats.syntax.all.*

enum Stream[A]:
  case Map[A, B](source: Stream[A], f: A => B) extends Stream[B]
  case Product[A, B](left: Stream[A],  right: Stream[B]) extends Stream[(A, B)]
  case FromIterator(it: Iterator[A])
  case FromSeq(seq: Seq[A])

  def map[B](f: A => B): Stream[B] =
    Map(this, f)

  def product[B](that: Stream[B]) =
    Product(this, that)

  def foldLeft[B](zero: B)(f: (B, A) => B): B =
    import Stream.Compiled

    val compiled = Stream.Compiled.fromStream(this)

    def next[C](compiled: Compiled[C]): Option[C] =
      compiled match
        case Compiled.Map(source, f) => next(source).map(f)
        case Compiled.Product(left, right) => (next(left), next(right)).tupled
        case Compiled.FromIterator(it) => if it.hasNext then Some(it.next) else None
        case c @ Compiled.FromSeq(seq, idx) =>
          if idx == seq.size then None
          else
            val elt = seq(idx)
            c.idx = idx + 1
            Some(elt)

    def loop(zero: B): B =
      next(compiled) match
        case Some(v) => loop(f(zero, v))
        case None => zero

    loop(zero)

object Stream:
  enum Compiled[A]:
    case Map[A, B](source: Compiled[A], f: A => B) extends Compiled[B]
    case Product[A, B](left: Compiled[A],  right: Compiled[B]) extends Compiled[(A, B)]
    case FromIterator(it: Iterator[A])
    case FromSeq(seq: Seq[A], var idx: Int = 0)

  object Compiled:
    import Compiled.*

    def fromStream[A](stream: Stream[A]): Compiled[A] =
      stream match
        case Stream.Map(source, f) => Map(fromStream(source), f)
        case Stream.Product(left, right) => Product(fromStream(left), fromStream(right))
        case Stream.FromIterator(it) => FromIterator(it)
        case Stream.FromSeq(seq) => FromSeq(seq)

  def fromIterator[A](it: Iterator[A]): Stream[A] =
    Stream.FromIterator(it)

  def fromSeq[A](seq: Seq[A]): Stream[A] =
    Stream.FromSeq(seq)
```

This is one of the longer code examples we've seen, but the changes are reasonably simple:

- We introduce a `FromSeq` case to `Stream`.
- We define a new algebraic data type, `Compiled`, to represent the target we compile `Stream` into. This structure mirrors `Stream` exactly, except `FromSeq` has a mutable index.
- Compilation is a straightforward structural recursion, defined in `fromStream`.
- We hide `next` within `foldLeft`, and rework `foldLeft` to work on a compiled version of the `Stream`. As the stateful compiled `Stream` is only visible within `foldLeft`, none of the state can escape beyond the call to `foldLeft`.

If we define a `Stream` containing a `Seq`

```scala mdoc:silent
val s = Stream.fromSeq(Seq(1, 2, 3))
```

we get the correct result when we run it multiple times:

```scala mdoc
s.foldLeft(Seq.empty)(_ :+ _)

s.foldLeft(Seq.empty)(_ :+ _)
```
