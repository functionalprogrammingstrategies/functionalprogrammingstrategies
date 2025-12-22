#import "../stdlib.typ": exercise, solution, href
== Opaque Types <sec:types:opaque-types>

Let's now look at opaque types.
Opaque types are a Scala 3 feature that decouple the representation of a type from the set of allowed operations on that type.
In simpler words, they allow us to create a type (e.g. an `EmailAddress`) that has the same runtime representation as another type (e.g. a `String`),
but is distinct from that type in all other ways.
For example, here's a definition of `EmailAddress` as an opaque type.

```scala mdoc:silent
opaque type EmailAddress = String
object EmailAddress {
  def apply(address: String): EmailAddress = {
    assert(
      {
        val idx = address.indexOf('@')
        idx != -1 && address.lastIndexOf('@') == idx
      },
      "Email address must contain exactly one @ symbol."
    )
    address.toLowerCase
  }
}
```

```scala mdoc:invisible:reset
// We need to redefine the opaque type within an object
// to ensure it's not transparent to the following examples
object Opaque {
  opaque type EmailAddress = String
  object EmailAddress {
    def apply(address: String): EmailAddress = {
      assert(
        {
          val idx = address.indexOf('@')
          idx != -1 && address.lastIndexOf('@') == idx
        },
        "Email address must contain exactly one @ symbol."
      )
      address.toLowerCase
    }
  }
}
import Opaque.*
```

Notice that I need to define a constructor to create an `EmailAddress`,
which is the `apply` method on the `EmailAddress` companion object,
in addition to the `opaque type` definition of `EmailAddress` itself.
Also notice that the constructor returns just the `address`, so long as it passes validation.
Here's an example, showing the result type `EmailAddress`

```scala mdoc
val email = EmailAddress("someone@example.com")
```

This shows that an `EmailAddress` is represented as a `String`,
but as far as the type system is concerned it is not a `String`.
We cannot, for example, call methods defined on `String` on an instance of `EmailAddress`.
#footnote[
    Scala usually runs on the JVM, and the JVM was not designed to support opaque types.
    This means there are, unfortunately, a few ways to poke holes in the abstraction boundary created by an opaque type.
    If we use `isInstanceOf`, we can test for the underlying representation.
    Using the methods defined on `Object` (`Any` in Scala), namely `equals`, `hashCode`, and `toString`, also allow us to peek inside.
]

```scala
email.toUpperCase
// Compiler says NO!
```

We can view this as an efficiency gain.
Our `EmailAddress` uses exactly the same amount of memory as the underlying `String` that represents it,
yet it is a different type.
Alternatively, we can view it as a semantic gain.
An `EmailAddress` _is_ a sequence of characters,
the same as a `String`,
but it has additional properties.
In this case we verify it contains exactly one `@` character,
and our email addresses are case insensitive.

This is good but how do we define methods?

To understand how opaque types work, we need to understand they divide our code base into two distinct parts: those where our type transparent, that is where we know the underlying representation, and the remainder where it is opaque.
The rule is pretty simple: an opaque type is transparent within the scope in which it is defined. 
Within an object.

If it's defined at the top-level, its transparent within the file.
Otherwise it's opaque.

Extension methods.
- Defined on companion object?

equals and toString
