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

Now we have two options for dealing with the dependency: we can move it before the functions or we move it after the function.
Showing this in code will make it clearer.
First, we move the dependnecy before the functions.

```scala mdoc:silent:nest
val userDb = (database: DatabaseConnection) =>
  val getUser: (UserId, DatabaseConnection) => User =
    (id, database) => ???

  val saveUser: (User, DatabaseConnection) => Unit =
    (id, database) => ???

  // Return the two functions
  (getUser, saveUser)
```

In this version we must supply the `DatabaseConnection` dependency before we create `getUser` and `saveUser`.
We return a tuple of the functions, which is a bit awkward to work with. We'll return to this in a moment.

First we'll look at the alternative, moving the dependencies after the functions.
Now `getUser` and `saveUser` are functions as before, but we only pass the parameters that are not a dependency.
We get back a function that requires a dependency.
As you may recall, this is exactly the reader monad.

```scala mdoc:silent:nest
val getUser: UserId => DatabaseConnection => User =
  id => database => ???

val saveUser: User => DatabaseConnection => Unit =
  user => database => ???
```


