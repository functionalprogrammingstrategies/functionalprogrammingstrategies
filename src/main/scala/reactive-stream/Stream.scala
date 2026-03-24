package reactivestream

import cats.syntax.all.*

enum Stream[A]:
  case Filter(source: Stream[A], predicate: A => Boolean)
  case Map[A, B](source: Stream[A], f: A => B)
      extends Stream[B]
  case Merge(left: Stream[A], right: Stream[A])
  case Product[A, B](left: Stream[A], right: Stream[B])
      extends Stream[(A, B)]
  case Take(source: Stream[A], count: Int)
  case FromIterator(it: Iterator[A])
  case FromSeq(seq: Seq[A])

  def filter(pred: A => Boolean): Stream[A] =
    Filter(this, pred)

  def map[B](f: A => B): Stream[B] =
    Map(this, f)

  def merge(that: Stream[A]): Stream[A] =
    Merge(this, that)

  def product[B](that: Stream[B]) =
    Product(this, that)

  def take(count: Int): Stream[A] =
    Take(this, count)

  def foldLeft[B](zero: B)(f: (B, A) => B): B =
    import Stream.Compiled
    import Stream.Emit

    val compiled = Compiled.fromStream(this)

    def loop(zero: B): B =
      compiled.next() match
        case Emit.Value(v) => loop(f(zero, v))
        case Emit.Wait     => loop(zero)
        case Emit.End      => zero

    loop(zero)

  def toSeq: Seq[A] =
    foldLeft(Seq.empty)(_ :+ _)

object Stream:
  enum Emit[+A]:
    // The pull produced a value
    case Value(get: A)
    // There is not value available now, but may be in the future
    case Wait
    // The stream has ended and no values will be available
    case End

    def map[B](f: A => B): Emit[B] =
      this match
        case Value(get) => Value(f(get))
        case Wait       => Wait
        case End        => End

    def flatMap[B](f: A => Emit[B]): Emit[B] =
      this match
        case Value(get) => f(get)
        case Wait       => Wait
        case End        => End

  enum MergeDirection:
    case PullLeft
    case PullRight

  enum ProductState[+A, +B]:
    // Pull from both left and right
    case Continue
    // Right value is cached. Pull from left
    case CacheRight(right: B)
    // Left value is cached. Pull from right
    case CacheLeft(left: A)
    // Upstream has ended
    case End

  enum Compiled[A]:
    case Filter(
        source: Compiled[A],
        predicate: A => Boolean
    )
    case Map[A, B](source: Compiled[A], f: A => B)
        extends Compiled[B]
    case Merge(
        left: Compiled[A],
        right: Compiled[A],
        var direction: MergeDirection
    )
    case Product[A, B](
        left: Compiled[A],
        right: Compiled[B],
        var state: ProductState[A, B]
    ) extends Compiled[(A, B)]
    case Take(source: Compiled[A], var count: Int)
    case FromIterator(it: Iterator[A])
    case FromSeq(seq: Seq[A], var idx: Int = 0)

    def next(): Emit[A] =
      this match
        case Compiled.Filter(source, pred) =>
          source
            .next()
            .flatMap(a =>
              if pred(a) then Emit.Value(a) else Emit.Wait
            )
        case Compiled.Map(source, f) => source.next().map(f)
        case c @ Compiled.Merge(left, right, direction) =>
          direction match
            case MergeDirection.PullLeft =>
              c.direction = MergeDirection.PullRight
              left.next()
            case MergeDirection.PullRight =>
              c.direction = MergeDirection.PullLeft
              right.next()
        case c @ Compiled.Product(left, right, state) =>
          import ProductState.*

          state match
            case End      => Emit.End
            case Continue =>
              (left.next(), right.next()) match
                case (Emit.End, _) =>
                  c.state = End
                  Emit.End
                case (_, Emit.End) =>
                  c.state = End
                  Emit.End
                case (Emit.Wait, Emit.Wait) =>
                  Emit.Wait
                case (Emit.Wait, Emit.Value(r)) =>
                  c.state = CacheRight(r)
                  Emit.Wait
                case (Emit.Value(l), Emit.Wait) =>
                  c.state = CacheLeft(l)
                  Emit.Wait
                case (Emit.Value(l), Emit.Value(r)) =>
                  Emit.Value((l, r))
            case CacheRight(r) =>
              left.next() match
                case Emit.End =>
                  c.state = End
                  Emit.End
                case Emit.Wait     => Emit.Wait
                case Emit.Value(l) =>
                  c.state = Continue
                  Emit.Value((l, r))
            case CacheLeft(l) =>
              right.next() match
                case Emit.End =>
                  c.state = End
                  Emit.End
                case Emit.Wait     => Emit.Wait
                case Emit.Value(r) =>
                  c.state = Continue
                  Emit.Value((l, r))
        case c @ Compiled.Take(source, count) =>
          if count == 0 then Emit.End
          else
            source.next() match
              case Emit.Value(get) =>
                c.count = count - 1
                Emit.Value(get)
              case Emit.Wait =>
                // Waits don't change the count
                Emit.Wait
              case Emit.End =>
                c.count = 0
                Emit.End
        case Compiled.FromIterator(it) =>
          if it.hasNext then Emit.Value(it.next)
          else Emit.End
        case c @ Compiled.FromSeq(seq, idx) =>
          if idx == seq.size then Emit.End
          else
            val elt = seq(idx)
            c.idx = idx + 1
            Emit.Value(elt)

  object Compiled:
    def fromStream[A](stream: Stream[A]): Compiled[A] =
      stream match
        case Stream.Filter(source, pred) =>
          Filter(fromStream(source), pred)
        case Stream.Map(source, f) =>
          Map(fromStream(source), f)
        case Stream.Merge(left, right) =>
          Merge(
            fromStream(left),
            fromStream(right),
            MergeDirection.PullLeft
          )
        case Stream.Product(left, right) =>
          Product(
            fromStream(left),
            fromStream(right),
            ProductState.Continue
          )
        case Stream.Take(source, count) =>
          Take(fromStream(source), count)
        case Stream.FromIterator(it) => FromIterator(it)
        case Stream.FromSeq(seq)     => FromSeq(seq)

  def fromIterator[A](it: Iterator[A]): Stream[A] =
    Stream.FromIterator(it)

  def fromSeq[A](seq: Seq[A]): Stream[A] =
    Stream.FromSeq(seq)
