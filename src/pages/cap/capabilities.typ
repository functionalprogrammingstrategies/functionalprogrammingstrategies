== Effects, Context, and Capabilities

Let's begin by defining capabilities.
To do so, we need to talk about context and effects.
We first met context in @sec:type-classes, and effects have been a theme throughout the book,
but we'll be a little bit more formal here.
This in turn will allow us to talk about capabilities and hence capability-passing.
After all this theory, we'll find ourselves back in familiar territory
but with a new mental model to appreciate what we're doing.

=== Effects, Context

An effectful expression is anything that interacts with the surrounding environment in which it is evaluated.
We call the interaction an effect, and the surrounding environment the context.
Effects can be a dependency on the context, or a modification of the context.
For example, if we have a function `A => B` that also depends on some value `c` in scope,
we say that `c` is part of the context and the way it uses `c` is an effect.

```scala
val c: A = ???
val f: A => B = a => makeB(a, c)
```

In the example above the effect may be completely benign,
and not worth worrying about.
Or it could be a tricky concurrent operation that may produce errors.
It all depends on what `makeB` does.
One of the goals with effect handlers is to surface this information,
so we can tell at a glance if calling a function is something to pay extra attention to.
We're still being relatively informal in our discussion.
If you want more formality please see the references in @sec:cap:conclusions.


=== Capabilities

A capability is something that provides the ability to carry out an effect.
For example, in Scala we can think of an `ExecutionContext` as providing the capability to execute asynchronously.
Capability-passing, then, is simply the idea that programs explicitly declare the capabilities they require,
and we pass in those capabilities when we run them.
There is a bit more complexity to make everything work nicely, but really the core idea is that simple.
This is exactly what tagless final does, which we met in @sec:tagless-final.
When we wrote a program in tagless final style, and created a program with a type like

```scala
Program[Controls & Layout, Tuple2[String, Int]]
```

the first part of that type, `Controls & Layout`, is expressing exactly the capabilities the program requires to run.
Similarly, when we discussed dependency injection in @sec:di we saw that the core is simply passing things to constructors or methods.
The things we pass we can view as capabilities, and so the essence of capability-passing is dependency injection (or vice versa, if you prefer.)

If capability-passing really is this simple, why do we have a whole chapter devoted to it?
One reason is that there is a little bit more to capability-passing than just passing stuff around.
We'll get to that towards the end of the chapter.
More important, though, is the different mental model capability-passing provides.
This is where we'll spend the majority of our time.
We'll build a simple user interface toolkit using capability-passing style,
which we can compare to the one we created in @sec:tagless-final:aui using tagless final.
We'll see a slightly different approach gives us a different outcome.
