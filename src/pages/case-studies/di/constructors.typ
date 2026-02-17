#import "../../stdlib.typ": href
== Constructors Injection and the Reader Monad

In this section we'll look at two fundamental approaches to dependency injection: passing arguments to constructors, which is sometimes known as *constructor injection*, and the reader monad, which we met in @sec:monads:reader.
We'll see how each works, and then looks at how they are related.
We will discover there is a duality between them, and they represent a comonadic and monadic approach respectively.

As a running example we'll use the following two methods, which represent how we might work with a simple `User` type stored in a database. The `DatabaseConnection` type is the dependency that we wish to inject.

```scala mdoc:invisible
type UserId = Int
type DatabaseConnection = String
type User = String
```
```scala mdoc:silent
def getUser(database: DatabaseConnection, id: UserId): User =
  ???

def saveUser(database: DatabaseConnection, user: User): Unit =
  ???
```

=== Constructor Injection

Representing dependencies as constructor parameters is the most basic approach to dependency injection in an object-oriented language.
Applying this technique to our example above means moving the methods into a class with the `DatabaseConnection` as a constructor parameter.

```scala mdoc
class UserDb(database: DatabaseConnection):
  def getUser(id: UserId): User =
    ???

  def saveUser(user: User): Unit =
    ???
```

This is called constructor injection in the dependency injection literature, and we'll use this term for clarity.
However is a very basic object-oriented programming technique, so you are probably familiar with it regardless of your experience with dependency injection.


We have seen how to write code that requires dependencies. How do we use this code? Let's imagine we have a method that updates a `User`.
It might have the skeleton

```scala
def updateUser(id: UserId): Unit =
  val user = getUser(id)
  // Do stuff here
  saveUser(user)
```

With constructor injection this method now requires a `UserDb` instance. We could add this as another parameter

```scala mdoc:silent
def updateUser(db: UserDb, id: UserId): Unit =
  val user = db.getUser(id)
  // Do stuff here
  db.saveUser(user)
```

or apply constructor injection again, if there are multiple related methods that have the same dependency.

```scala mdoc:nest:silent
class UserActions(db: UserDb):
  def updateUser(id: UserId): Unit =
    val user = db.getUser(id)
    // Do stuff here
    db.saveUser(user)
```

Finally, let's look at how we provide dependencies to classes that require them.

```scala
val database = DatabaseConnection(...)
val userDb = UserDb(database)
val userActions = UserActions(userDb)
val userId = ...

userActions.updateUser(userId)
```

This is very basic code: we just pass the values as the constructors. However, this can cause issues in larger code bases. One problem is the annoynace caused by passing many dependencies into deeper layers of the code. This is sometimes called *tramp data*. The other issue can be the complexity of creating dependencies. In our example above we have have a chain three deep, from the `UserActions` to the `DatabaseConnection`. This can be much larger in a real code base, and it can be problematic to find needed dependencies. These are the main problems that dependency injection frameworks, like #href("https://github.com/google/guice")[Guice], set out to solve#footnote[
    We're aren't going to look at any particular frameworks in this section. This is for several reasons. Firstly, this book is focused on reusable ideas, not the particulars of any one library. Secondly, the common dependency injection frameworks rely on runtime reflection, which is counter to the principle of reasoning we discussed way back in @sec:what-is-fp. Finally, we have much better solutions in expressive languages like Scala.
].


=== The Reader Monad

We met the reader monad in @sec:monads:reader, but we'll recap it here.
Using the reader monad means changing our methods to return an instance of the reader monad that accepts the `DatabaseConnection`.

```scala mdoc:silent:nest
import cats.data.Reader

def getUser(id: UserId): Reader[DatabaseConnection, User] =
  ???

def saveUser(user: User): Reader[DatabaseConnection, Unit] =
  ???
```

We can call `getUser` and `saveUser` as normal. However, as they now return instances of the reader monad we must use `flatMap` and the like to compose the results together. Our example `updateUser` method could look like

```scala mdoc:silent
def updateUser(id: UserId): Reader[DatabaseConnection, Unit] =
  for {
    user <- getUser(id)
    // Do stuff here
    _ <- saveUser(user)
  } yield ()
```

Not only does the result type change, but we must rewrite the body from direct style to monadic style. 

Finally, to provide the dependencies we simply apply the reader monad to them.

```scala
val database = DatabaseConnection(...)
val program: Reader[DatabaseConnection, Unit] = updateUser(userId)

program(database)
```

The reader monad looks simple in this small example. However, just like constructor injection it does bring issues. The two main ones are transforming our code in monadic style, which is annoying to do at large scale, and the work we have to do to compose multiple different dependencies in the monad.


=== Relating Constructor Injection and the Reader Monad

Now that we have seen constructor injection and the reader monad, let's look at the relationship between them.
We'll find there is a duality between them, meaning we can convert between the two by a simple transformation.
We'll also discover that constructor injection is an object-oriented realization of a *comonad* known as the environment comonad,
which is the dual to reader.

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

Now `getUser` and `saveUser` are functions as before, but they only need the parameters that are not a dependency.
They return a function requiring the dependency; hence we supply the dependency after calling the functions.
This is the reader monad.

In the reader monad world we end up with lots of functions that require dependencies.
The reader monad handles this is by giving us combinators---`flatMap`, `map`, and friends---that allow us to compose these functions into a single function that takes all the needed dependencies.

Let's now look at moving the dependencies before the functions.

```scala mdoc:silent:nest
val getUser: DatabaseConnection => UserId => User =
  database => id => ???

val saveUser: DatabaseConnection => User => Unit =
  database => user => ???
```

In this version we must supply the `DatabaseConnection` dependency before the non-dependency parameters.
We could work with this code in the reader monad, but it is substantially more annoying to do so.
In the usual reader monad we only have to combine the results of calling the functions we want.
In this encoding we have to reach inside the monads to actually call the functions we are after.

Let's simply this code.
Notice that both functions have the same first parameter.
We can define a single function of the dependency, which in turn returns two functions.

```scala mdoc:silent:nest
val userDb = (database: DatabaseConnection) =>
  val getUser: UserId => User =
    id => ???

  val saveUser: User => Unit =
    id => ???

  // Return the two functions
  (getUser, saveUser)
```

It's a bit awkward to work with a tuple of functions.
Better if we can name this tuple, so that where we require one or both of these functions we can just refer to the name.
We can create a name by defining a class.

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

To recap, constructor injection requires the dependency before the function, while the reader monad requires the dependency after the function.
We can transform one into the other, as we've seen above, and therefore they are duals.

This duality illustrates the importance of craft.
Both approaches are equivalent, as we have shown, but they are not equally idiomatic in any given language.
In a language with good support for object-oriented programming, or codata as we might prefer to call it,
constructor injection works very well.
The core is that we can name the result type, the `UserDb`, so other functions can just require a value of that type.
In languages without such good support, the reader monad might be a better solution, though it requires we rewrite our code in monadic style.

There is one important difference between the reader monad and constructor injection.
The reader monad is a value, which we pass around in our program.
Instances of a class, that is objects, are values.
Classes, however, are not usually values.
They certainly aren't in Scala.
What would it mean for classes to be values in constructor injection?
Let's return to the reader monad implementation of `getUser`, which was

```scala mdoc:silent
val getUser: UserId => DatabaseConnection => User =
  id => database => ???
```

or it's equivalent directly using the reader monad

```scala mdoc:nest:silent
val getUser: UserId => Reader[DatabaseConnection, User] =
  id => Reader(database => ???)
```

In the abstract, this function has type

```scala
A => F[B]
```

which you probably recognize as the type of the function passed to `flatMap`.
Following this thread takes us to implementing the reader monad in terms of klesli arrows, which was briefly mentioned in 
@sec:monads:reader.
However, let's go in a different direction.

If we were to represent the constructor injection code as values, that is as a functions, we might define functions like

```scala mdoc:nest:silent
val getUser: DatabaseConnection => UserId => User =
  database => id => ???
```

We could try to represent this as `Reader[DatabaseConnection, UserId => User]` but that's not a useful representation to work with.
We can *uncurry*#footnote[
    Currying is transformation from a function of multiple parameters, such as
    
``` scala:mdoc:silent
(x: Int, y: Int, z: Int) => x + y + z
```
    to a function of single parameters, such as

``` scala:mdoc:silent
(x: Int) => (y: Int) => (z: Int) => x + y + z
```

    Uncurrying is the inverse, transforming a function of single parameters into one of multiple parameters. And yes, they are dual!
] to obtain

```scala mdoc:silent:nest
val getUser: (DatabaseConnection, UserId) => User =
  (database, id) => ???
```

This basically the method we originally started with. What if we think of the parameters as a tuple `(DatabaseConnection, UserId)`? This looks like the writer monad, introduced in @sec:monads:writer. We can try

```scala mdoc:silent:nest
import cats.data.Writer

val getUser: Writer[DatabaseConnection, UserId] => User =
  writer => ???
```

with the idea being that `Writer[DatabaseConnection, UserId]` represents a `UserId` along with some value we want from the environment or context, in this case a `DatabaseConnection`. In the abstract this looks like

```scala
F[A] => B
```

which is the dual of `flatMap`, sometimes known as `coflatMap`!

In practice we'll find that the writer monad doesn't support the API we want. What we want is a *comonad*, usually called the environment comonad. It's simply a comonad defined on the tuple `(E, A)`, where `E` is the environment and `A` is the normal value. There is no `Environment` type in Cats, but there is a `Comonad` type class and `Comonad` instance defined on `Tuple2`. We can easily define our own `Environment` comonad with these tools.

```scala mdoc:silent
import cats.Comonad

opaque type Environment[E, A] = (E, A)
object Environment:
  def apply[E, A](environment: E, value: A) = (environment, value)
  def apply[E, A](tuple: (E, A)) = tuple

  extension [E, A](e: Environment[E, A])
    def environment: E = e(0)

  given [E] => Comonad[[A] =>> Environment[E, A]] = summon[Comonad[[A] =>> (E, A)]]
```
