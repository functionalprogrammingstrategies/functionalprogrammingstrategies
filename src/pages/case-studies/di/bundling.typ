== Bundling Dependencies

Contextual abstraction removes some of the tedium of providing dependencies but it has a limitation that is not so apparent in small examples. Dependencies are usually thought of as a set of related types. We often want to swap out the entire set in one go. For example, we'll use different dependencies in testing and production, and if our application is deployed across multiple regions the dependencies will vary by data center. Representing them as a scattered collection of `given` instances tends to make this difficult to maintain. 

This problem arises because we cannot abstract over a parameter list: parameter lists are not values and, as such, there is no way to define a type for a set of parameters. The solution is simply to stop working with parameter lists, and work instead with a single value that represents all our dependencies. This leads to question of how we build this value, which we call the *bundling problem*. In the next three sections  we look at solutions to this problem: algebraic data types, the so-called Cake pattern, and tagless final style, which we first met in @sec:tagless-final.


=== Algebraic Data

In many situations it's sufficient to represent the dependencies as a simple product type; a `final case class` in Scala. This is extremely straightforward, and perhaps obvious, but I want to highlight it as it's the best solution in very many situations. The more complicated Cake pattern should be reserved for when it is truly justified.


=== The Cake Pattern

The Cake pattern is uses inheritance as a form of module composition, working as follows:

- modules are defined as classes;
- self types define module requirements; and
- abstract types hide information about the representation of components.

Let's walk through each of these, starting with modules.

Modules are a loosely defined concept; for our purposes we're interested in three properties. Firstly, a module allows us to name a set of related definitions. Secondly, modules separate interface from implementation. Finally, modules can depend on and be combined with other modules. If this sounds a lot like a class, it indeed the case. In my opinion, understanding self types is the key to understanding how modules using the Cake pattern differ from standard object oriented techniques. Let's turn to them.

Self types are a fairly unique feature in Scala, so we'll spend some time going through the mechanics. They are written like so:

```scala mdoc:silent
trait Example:
  self =>
    val theAnswer: Int = 42
  
    def calculateAnswer: Int =
    self.theAnswer
```

where `self` is the self type. In this example the self type just gives another name to `this`. The real power comes when we attach a type declaration to the self type. Consider the example below:

```scala mdoc:nest:silent
trait Answer:
  def theAnswer: Int

trait Example:
  self: Answer =>
    def calculateAnswer: Int =
      self.theAnswer
```

Operationally, the declaration `self: Answer` says that to create a concrete class implementing `Example` we must mix in an instance of `Answer`.

```scala mdoc:silent
trait AGoodAnswer extends Answer:
  def theAnswer: Int = 42

class ConcreteExample() extends Example, AGoodAnswer

val theExample = ConcreteExample()
```

Semantically, a self type describes a dependency: the `Example` module depends on the `Answer` module. We could implement this with a constructor parameter, or inheritance, so what does the self type bring? Compared to constructor parameters, self types allow cyclic dependencies. That is, a module `A` can depend on `B` and `B` can also depend on `A`. Compared to inheritance, self types do not define a subtyping relationship. If `A extends B`, then `A` is a subtype of `B`. The self type `self: Answer` on `Example` declares a requirement for an `Answer` but does not make `Example` a subtype of `Answer`.

Let's see a more complex example. In the previous section we used database access as our motivating example. Let's extend that, as it will give us the chance to demonstrate abstract types, the final part of the Cake pattern.

We're going to start by defining a connection pool type. 

```scala mdoc:invisible
type Row = String
```
```scala mdoc:silent
trait ConnectionPool:
  type Connection

  def acquire(): Connection
  def release(c: Connection): Unit

  def withConnection[A](f: Connection => A): A =
    val c = acquire()
    try f(c)
    finally release(c)

  def query(sql: String): Seq[Row]
```

The type of connections is defined as an abstract type. This means the type is hidden from users of `ConnectionPool`; they can acquire and release connections, and run queries against them, but not other operations with a connection. This gives implementations of `ConnectionPool` the freedom to to realize the `Connection` type as needed. In production we'll probably want a real connection pool, using whatever types it provides for connections, but in testing we might use an in-memory database using a different connection type. Finally, in a real system we'd hopefully have a much better implementation of `query`.

Let's create a module that uses `ConnectionPool`. The `UserDb` we saw earlier is a natural choice.

```scala mdoc:invisible
type UserId = Int
type User = String
```
```scala mdoc:silent
trait UserDb:
  self: ConnectionPool =>

    def getUser(id: UserId): User
    def saveUser(user: User): Unit
```

Note that `UserId` and `User` are not defined as abstract types. This indicates that we do not expect to need to vary the implementation of these types.

With `UserDb` we've defined a pure interface as a module. A concrete implementation of this would need to match 

```scala mdoc:silent
trait Runtime extends UserDb, ConnectionPool:
  type Connection = String

  def acquire(): Connection = "connection"
  def release(c: Connection): Unit = ()

  def getUser(id: UserId): User =
    withConnection { conn =>
      query(s"SELECT * FROM USERS WHERE id=$id").head
    }

  def saveUser(user: User): Unit
```


==== Cake Pattern Best Practices

You can perhaps see that you could build an entire application using just the Cake pattern. I strongly advise against this. It has several disadvantages. This style of coding in unfamiliar to many, and so makes code bases less accessible.

Order of evaluation




Behind dependency injection is the idea that we can divide our program into two parts: the dependencies and the application code. 

It's similar in approach to the module systems in Standard ML and OCaml


TODO: One solution to the bundling problem is to compose dependency modules using trait composition---the Cake pattern (or ML-style modules). Show how traits define interfaces for bundles of related operations, and how `extends` and self-types allow composing several such bundles into a single "application" object. The Cake pattern makes the bundle itself a first-class value that can be provided as a single `given` instance. Note connections to codata / objects-as-modules from @sec:codata.


=== Tagless Final

TODO: Recall tagless final from @sec:tagless-final. Show that the tagless final algebra is exactly a bundle of related operations parameterized by an abstract effect type `F[_]`. Providing a `given` instance of the algebra is providing the bundle of dependencies. The `F[_]` parameter additionally abstracts over *how* the effects are executed, which the reader monad approach cannot express. This makes tagless final a natural DI solution that grows out of the bundling problem.
