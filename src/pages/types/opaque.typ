#import "../stdlib.typ": exercise, solution, href
== Opaque Types <sec:types:opaque-types>

Let's now look at opaque types.
Opaque types are a Scala 3 feature that decouple the representation of a type from the set of allowed operations on that type.
In simpler words, they allow us to create a type (e.g. an `EmailAddress`) that has the same runtime representation as another type (e.g. a `String`),
but is distinct from that type in all other ways.
For example, here's a definition of `EmailAddress` as an opaque type.
Notice that I need to define a constructor to create an `EmailAddress`, in addition to the `opaque type` definition of `EmailAddress` itself.
Also notice that the constructor returns just the `address`, so long as it passes validation.

```scala mdoc:silent
opaque type EmailAddress = String
object EmailAddress {
  def apply(address: String): EmailAddress = {
    assert(
      address.contains('@'),
      "Email address must contain an @ symbol."
    )
    address
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
        address.contains('@'),
        "Email address must contain an @ symbol."
      )
      address
    }
  }
}
import Opaque.*
```

Here's an example of use.

```scala mdoc
val email = EmailAddress("someone@example.com")
```

If we try to call a method defined on `String` on an instance of `EmailAddress` we see it doesn't work.

```scala
email.toUpperCase
// Compiler says NO!
```

We can view this as an efficiency gain.
Our `EmailAddress` uses exactly the same amount of memory as the underlying `String` that represents it.
Alternatively, we can view it as a semantic gain.
An `EmailAddress` _is_ a sequence of characters,
the same as a `String`,
but it has additional properties.

This is good but how do we define methods?

To understand how opaque types work, we need to understand they divide our code base into two distinct parts: those where our type transparent, that is where we know the underlying representation, and the remainder where it is opaque.
The rule is pretty simple: an opaque type is transparent within the scope in which it is defined. 
Within an object.

If it's defined at the top-level, its transparent within the file.
Otherwise it's opaque.

Extension methods.
