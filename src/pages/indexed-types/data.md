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

This is indexed data, as it meets the criteria above: we have a single type parameter `A`, and the case `VString`, `VInt`, and `VDouble` instantiate that parameter with a concrete type.
The natural next question is why is this useful?
It will take a more involved example to show why, so let us now dive into one that makes good use of indexed data.

Our case study 

