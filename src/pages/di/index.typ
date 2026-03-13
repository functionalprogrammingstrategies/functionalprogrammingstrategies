#import "../stdlib.typ": info, warning, solution, chapter
#chapter[Dependency Injection] <sec:di>

This chapter is about dependency injection. This is a common problem in large code bases.

We're going to look at three characteristics: how we write code that requires dependencies, how we use code that requires dependencies, and how we provide dependencies.

The discussion here is focused on language features that are broadly within the strategies we've already seen. This means we are not going to look at specific libraries, nor will we look at techniques code generation techniques such as macros. However we are going to look at first-class modules, and their implementation in Scala will introduce a new language feature: the self type.

Derive the reader monad and constructor parameters.

Dependency injection in interpreters.


== What Are Dependencies

Defining dependencies can feel like trying to define art. "I know it when I see it".

A useful definition is that a dependency is a method or function parameter that changes less frequently than other parameters. Imagine we have a method to lookup some `User` type by their unique identifier. This method is parameterized by both the user identifier and the database connection.

```scala
def getUser(id: UserId, database: DatabaseConnection): User
```

Normally it will be very rare for a call to `getUser` to request the same user as previous calls.
The database connection, however, is likely to be the same for every call.
In fact it's common for dependencies to only vary between different deployments, such as between production and testing or between different data centers.


== What Problem Dependency Injection Solves

Get the code its dependencies.

We only care about this if dependencies can change. This is often the case, at least for testing purposes, but if we don't need this flexibility we don't need dependency injection.


== Approaches to Dependency Injection

Now that we agree on what we mean by dependencies, let's talk about the approaches we'll look at:

- constructor injection
- the reader monad
- interpreters
- what's variously known as the Cake pattern, ML modules
