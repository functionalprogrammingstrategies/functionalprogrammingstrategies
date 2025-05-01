## Indexed Data

The key idea of indexed data is to encode type equalities in data.
When we come to inspect the data (usually, via structural recursion) we discover these equalities, which in turn limit what values we can produce. 
Notice, again, the duality with codata. 
Indexed codata limits methods we can call. 
Indexed data limits values we can produce.
Also, remember that indexed data is often known as generalized algebraic data types.
We are using the simpler term indexed data to emphasise the relationship to indexed codata,
and also because it's much easier to type!

Concretely, indexed data in Scala occurs when:

1. we define a sum type with at least one type parameter; and
2. cases within the sum instantiate that type parameter with a concrete type.

Let's see an example. In implementing a programming language we need some representation of values within the language.
Suppose our language supports strings, integers, and doubles, which we will represent with the corresponding Scala types.
The code below shows how we can implement this.

```scala mdoc:silent
enum Value[A] {
  case VString(value: String) extends Value[String]
  case VInt(value: Int) extends Value[Int]
  case VDouble(value: Double) extends Value[Double]
}
```

This is indexed data, as it meets the criteria above: we have a type parameter `A` that is instantiated with a concrete type in the cases `VString`, `VInt`, and `VDouble`.
The natural next question is why is this useful?
It will take a more involved example to show why, so let us now dive into one that makes good use of indexed data.


### The Probability Monad 

Our case study will be creating a probability monad. This is a composable abstraction for defining probability distributions. The probability monad has a lot of uses. The most relevant to most developers is generating data for property-based tests, so we'll focus on this use case. However, it can also be used, for example, for statistical inference or for creating generative art. See the conclusions (Section [@sec:indexed-types:conclusions]) for some pointers to these uses.

Let's start with an example of generating random data. [Doodle][doodle] is a Scala library for graphics and visualization. A core part of the library is representing colors. Doodle has two different representations, RGB and OkLCH, with conversions between the two. Testing these conversions is an excellent use of property-based testing. If we can generate many, say, random RGB colors, we can test the conversion by checking the roundrip from RGB to OkLCH and back results in the original color[^numerics]. 

To create an RGB color we need three unsigned bytes, so our first task is to define how we generate a random byte. Doodle happens to have an implementation of the probability monad that we will use. Here is how we can do it.

```scala mdoc:silent
import cats.syntax.all.*
import doodle.core.Color
import doodle.core.UnsignedByte
import doodle.random.{*, given}

val randomByte: Random[UnsignedByte] = 
  Random.int(0, 255).map(UnsignedByte.clip)
```

Note that once again we see the interpreter strategy. A `Random[UnsignedByte]` is a value representing a program that will generate a random `UnsignedByte` when it runs.

With three random unsigned bytes we can create a random RGB color.

```scala mdoc:silent
val randomRGB: Random[Color] =
  (randomByte, randomByte, randomByte).mapN((r, g, b) => Color.rgb(r, g, b))
```

We might want to check our code by generating a few random values.

```scala mdoc
randomRGB.replicateA(3).run
```

It seems to be working.

What we have seen is an illustration of using the probability monad to generate random data. The probability monad works the same way as every other algebra: we have constructors (`Random.int`), combinators (`map`, and `mapN`), and interpreters (`run`). Being a monad means the algebra has some specific structure. For example, it tells us that we have `pure` and `flatMap` available, from which we can derive `mapN`.

Let's sketch an plausible interface for our probability monad.

```scala
trait Random[A] {
  def flatMap[B](f: A => Random[B]): Random[B]
  
  def map[B](f: A => B): Random[B]
  
  def product[B](that: Random[B]): Random[(A, B)]
}
object Random {
  def pure[A](value: A): Random[A] = ???
  
  // Generate a uniformly distributed random  Double greater
  // than or equal to zero and less than one.
  val double: Random[Double] = ???
  
  // Generate a uniformly distributed random  Int
  val int: Random[Int] = ???
}
```

The interface has the minimum requirements to be a monad, and a few other combinators and constructors. We can make progress on the implementation by applying the reification strategy, introduced in Section [@sec:interpreters:reification].

```scala
enum Random[A] {
  def flatMap[B](f: A => Random[B]): Random[B] =
    RFlatMap(this, f)
  
  def map[B](f: A => B): Random[B] =
    RMap(this, f)
  
  def product[B](that: Random[B]): Random[(A, B)] =
    RProduct(this, that)
  
  case RFlatMap[A, B](source: Random[A], f: A => Random[B]) 
    extends Random[B]
  case RMap[A, B](source: Random[A], f: A => B) 
    extends Random[B]
  case RProduct[A, B](source: Random[A], that: Random[B])
    extends Random[(A, B)]
  case RPure[A](value: A)
  case RDouble extends Random[Double]
  case RInt extends Random[Int]
}
object Random {
  import Random.{RPure, RDouble, RInt}

  def pure[A](value: A): Random[A] = RPure(value)
  
  // Generate a uniformly distributed random  Double greater
  // than or equal to zero and less than one.
  val double: Random[Double] = RDouble
  
  // Generate a uniformly distributed random  Int
  val int: Random[Int] = RInt
}
```

[^numerics]: Due to numeric issues there may be small differences between the colors that we should ignore.

[doodle]: https://www.creativescala.org/doodle/
