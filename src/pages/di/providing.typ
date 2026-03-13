== Providing Dependencies

In the previous section we looked at two approaches for requiring dependencies, constructor injection and the reader monad, and saw they were duals. We now look at the other side of dependencing injection: providing dependencies to code that requires them. We saw the basic answer in the previous section---pass the values manually---but this quickly becomes tedious. This section develops better solutions.


=== The Two Problems of Dependency Provision

Manual dependency provision has two distinct problems: tramp data and the wiring problem.
Let's look at each in turn.

Tramp data is data that a method or class doesn't directly require, but needs because it is required by some method or class that it calls. In other words, tramp data is a *transitive dependency*. In the previous section we introduced two example methods working with a database connection dependency:

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

We might use these methods as show below.

```scala mdoc:silent
def updateUser(database: DatabaseConnection, id: UserId): Unit =
  val user = getUser(database, id)
  // Do stuff here
  saveUser(database, user)
```

Notice that `updateUser` requires a `DatabaseConnection` but doesn't directly use that connection; the requirement is there only so that the connection can be passed to the methods that do use it. This is an example of tramp data.

Constructor injection, which we saw in the previous section, can be a solution to tramp data. If we move the requirement for a `Databaseconnection` into the constructor of a `UserDb` class, `updateUser` can require a `UserDb` rather than a raw connection. Now `updateUser` only holds what it directly needs.

```scala mdoc:silent:nest
class UserDb(database: DatabaseConnection):
  def getUser(id: UserId): User =
    ???
  
  def saveUser(user: User): Unit =
    ???

def updateUser(userDb: UserDb, id: UserId): Unit =
  val user = userDb.getUser(id)
  // Do stuff here
  userDb.saveUser(user)
```

However, constructor injection does not address *the wiring problem*. At the entry point of our program---typically `main`---we must manually construct the entire dependency graph: instantiate each value in the right order and pass it to the constructors that need it. In a realistic application this graph can be many levels deep, and the wiring code becomes a significant maintenance burden in its own right. It is this problem that motivates the remainder of this section.


=== Contextual Abstraction

Scala's contextual abstraction facilities, first introduced in @sec:type-classes, are precisely a mechanism for threading values through a call stack. As such, they directly address the wiring problem. The approach is straightforward: `using` clauses express a requirement for a dependency while `given` instances provide the implementations. The compiler will match up `given` instances to `using` clauses, doing the wiring for us.

Let us return to our running example, and rework it to use contextual abstraction. We start by expressing our dependencies as `using` clauses.

```scala mdoc:silent:nest
class UserDb()(using database: DatabaseConnection):
  def getUser(id: UserId): User =
    ???
  
  def saveUser(user: User): Unit =
    ???

def updateUser(id: UserId)(using userDb: UserDb): Unit =
  val user = userDb.getUser(id)
  // Do stuff here
  userDb.saveUser(user)
```

Notice that the `UserDb` class uses a `using` parameter in its constructor. Many developers are familiar with `using` parameters in methods, but forget that constructors can also have them.

Now, so long as the dependencies are in the `given` scope, the compiler will provide them for us.
In the code below I define the dependencies as anonymous `given` values, declaring only their type.
Notice that I don't explicitly pass a `DatabaseConnection` to `UserDb`.
The compiler picks up the `given` value in scope, wiring it up for us.

```scala mdoc:invisible:nest
val aDatabaseConnection = "database-connection"
val aUserId = 1

// Redeclare because we provide concrete implementations of the methods
class UserDb()(using database: DatabaseConnection):
  def getUser(id: UserId): User =
    "user"
  
  def saveUser(user: User): Unit =
    ()
def updateUser(id: UserId)(using userDb: UserDb): Unit =
  val user = userDb.getUser(id)
  // Do stuff here
  userDb.saveUser(user)
```
```scala mdoc:silent
// Declare base dependencies
given DatabaseConnection = aDatabaseConnection

// Wiring happens automatically
given UserDb = UserDb()
```

When we call `updateUser` the compiler provides the `UserDb` dependency.

```scala mdoc:silent
updateUser(aUserId)
```

This approach works well in many cases, but there is an important limitation: recall that `given` values are matched to `using` clauses by the type of the parameter. This means that multiple different `given` values of the same type cannot be distinguished. Imagine if we had two different database connections, perhaps one to the master database for low volume writes, and one to a cluster of read-only replicas for reads. If they both have the type `DatabaseConnection` we cannot use contextual abstraction to distinguish them. There are two solutions: we can explicitly pass parameters, or we can distinguish based on type.

Explicitly passing parameters means exactly what it says: instead of letting the compiler find the `given` value we specify the value to use for the `using` clause. I do not recommend this approach for several reasons. Firstly, we are back in the inconvenience of manually providing dependencies. More importantly, this is a fragile practice. It is easy to overlook a case where we should manually provide a dependency, but if there is a `given` value in scope the compiler will automatically use it instead of giving us a compilation error.

The alternative is to distinguish the values by type, perhaps by using an opaque type as described in @sec:types. This is my preferred solution. It clearly distinguishes the values to the compiler, and the type also conveys meaning to the developer.

Contextual abstraction provides a good solution to providing dependencies. However, as a program evolves we will encounter another problem: that of maintaining dependencies.
