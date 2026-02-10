== Constructors Arguments and the Reader Monad

In this section we'll look at two very basic approaches to dependency injection: passing arguments to constructors and the reader monad.
We'll then see how we can derive them from as alternative implementations, thus establishing a duality between them.

*constructor injection*


=== Constructor Arguments

Passing dependencies as arguments to constructor parameters is the most basic approach in an object-oriented language.
For example, if we have methods with a `DatabaseConnection` dependency

```scala mdoc:invisible
type UserId = Int
type DatabaseConnection = String
type User = String
```
```scala mdoc:silent
def getUser(id: UserId, database: DatabaseConnection): User =
  ???

def saveUser(user: User, database: DatabaseConnection): Unit =
  ???
```

we could put them in a class with the `DatabaseConnection` as a constructor parameter.

```scala mdoc
class UserDb(database: DatabaseConnection):
  def getUser(id: UserId, database: DatabaseConnection): User =
    ???

  def saveUser(user: User, database: DatabaseConnection): Unit =
    ???
```

There's not much more to say about this.


=== The Reader Monad

We met the reader monad in @sec:monads:reader.


```scala mdoc:silent:nest
def getUser(id: UserId, database: DatabaseConnection): User =
  ???

def saveUser(user: User, database: DatabaseConnection): Unit =
  ???
```

to convert them to the reader monad we return an instance of the reader monad that accepts the `DatabaseConnection`.

```scala mdoc:silent:nest
import cats.data.Reader

def getUser(id: UserId): Reader[DatabaseConnection, User] =
  ???

def saveUser(user: User): Reader[DatabaseConnection, Unit] =
  ???
```

When we create these instances of the reader monad we must compose them together in the usual way with `flatMap` and the like, constructing one single reader monad value that represents our entire program. Here's a very simple example.

```scala mdoc:silent
def example(id: UserId): Reader[DatabaseConnection, Unit] =
  getUser(id).flatMap(user => saveUser(user))
```

This gives us a single value we must supply our dependencies to. When we do this our program will run.

Remember that in terms of the implementation, the reader monad is simply a function from the dependency to the result.


=== Converting Between Constructor Injection and the Reader Monad

Constructor injection and the reader monad are related by a duality, meaning we can convert between the two by a simple transformation.
Let's go back to our original example. We have two methods, both with a `DatabaseConnection` dependency.

```scala mdoc:silent:nest
def getUser(id: UserId, database: DatabaseConnection): User =
  ???

def saveUser(user: User, database: DatabaseConnection): Unit =
  ???
```

To make the rest of the derivation clearer I'm going to convert these methods to functions.

```scala mdoc:silent:nest
val getUser: (UserId, DatabaseConnection) => User =
  (id, database) => ???

val saveUser: (User, DatabaseConnection) => Unit =
  (id, database) => ???
```

Now we have two options for dealing with the dependency: we can move it before or after the functions.
We'll first look at moving the dependencies after the functions.

```scala mdoc:silent:nest
val getUser: UserId => DatabaseConnection => User =
  id => database => ???

val saveUser: User => DatabaseConnection => Unit =
  user => database => ???
```

Now `getUser` and `saveUser` are functions as before, but we only pass the parameters that are not a dependency.
We get back a function that requires the dependency, so we supply the dependencies after calling the functions.
As you may recall, this is the core of the reader monad.

In the reader monad world we end up with lots of little functions that require dependencies.
The way the reader monad handles this is by giving us combinators---`flatMap`, `map`, and friends---that allow us to compose these little functions into a single big function that takes all the needed dependencies.

Let's now look at moving the dependencies before the functions.

```scala mdoc:silent:nest
val getUser: DatabaseConnection => UserId => User =
  database => id => ???

val saveUser: DatabaseConnection => User => Unit =
  database => user => ???
```

In this version we must supply the `DatabaseConnection` dependency before we create the `getUser` and `saveUser` functions.
We could work with this code in the reader monad, but it is substantially more annoying to do so.
In the usual reader monad we only have to combine the results of calling the functions we want.
In this encoding we have to reach inside the monads to actually call the functions we are after.

Let's see if we can simply this code, and make it easier to work with.
The first thing we might notice is that both functions have the same first parameter.
We can define a single function of the dependency, which in turn returns two functions.

```scala mdoc:silent:nest
val userDb = (database: DatabaseConnection) =>
  val getUser: (UserId, DatabaseConnection) => User =
    (id, database) => ???

  val saveUser: (User, DatabaseConnection) => Unit =
    (id, database) => ???

  // Return the two functions
  (getUser, saveUser)
```

It's a bit awkward to work with a tuple of functions.
Better if we can name this tuple, so that where we require one or both of these functions we can just refer to the name.

```scala mdoc:silent:nest
abstract class UserDb {
  def getUser(id: UserId): User

  def saveUser(user: User): Unit
}

val userDb: DatabaseConnection => UserDb = database =>
  new UserDb {
    def getUser(id: UserId): User = ???
  
    def saveUser(user: User): Unit = ???
  }
```

At this point we should go ahead and define a normal class with a constructor parameter.

```scala mdoc:nest
class UserDb(database: DatabaseConnection) {
  def getUser(id: UserId): User = ???

  def saveUser(user: User): Unit = ???
}
```

What should we make of this duality?
It illustrates the effect that the language features have on our code.
Both approaches are equivalent, as we have shown, but each is more idiomatic in any given languages.
In a language with good support for object-oriented programming, or codata as we might prefer to call it,
constructor injection works very well.
The core is that we can name the result type, the `UserDb`, so other functions can just require a value of that type.
In languages without such good support, we could use a tuple or a record type, which works but is less idiomatic.
There is no correct solution absent the context in which the solution is used.
