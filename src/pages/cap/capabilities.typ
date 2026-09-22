== Effects, Context, and Capabilities

Let's start by defining capabilities.
To do so, we first need to talk about context and effects.
We first met context in @sec:type-classes, and effects have been a theme throughout the book,
but we'll be a little bit more formal here.
This in turn will allow us to talk about capabilities and hence capability-passing.
After all this theory, we'll find ourselves back in familiar territory
but with a new framing to appreciate what we're doing.

=== Effects and Context

An effectful expression interacts with the surrounding environment in which it is evaluated.
We call the interaction an effect, and the surrounding environment the context.
Effects can be a dependency on or a modification of the context.
For example, an effect could be a modification of an in-memory key-value store,
or it could be a dependency on a network connection to read packets.
One of the goals of effect systems is to surface the effects of a function,
so we can tell at a glance if calling that function is something to pay extra attention to.


=== Capabilities

A capability is something that provides the ability to carry out an effect.
For example, in Scala we can think of an `ExecutionContext` as providing the capability to execute asynchronously.
We can define the context as the set of available capabilities along with the state of any resources that the capabilities control.

What we choose to define as a capability is a design decision.
It comes down to what we want to explicitly track and control access to.
For example, in general programming we freely allocate memory and would not consider memory allocation to be a capability,
However, in systems programming this is often not the case and therefore memory allocation would be considered a capability.

Capability-passing is simply the idea that programs explicitly declare the capabilities they require,
and we pass in those capabilities when we run them.
There is a bit more complexity to make everything work nicely, but the core idea really is that simple.
This is exactly what tagless final does, which we met in @sec:tagless-final.
In tagless final style we wrote programs with types like

```scala
Program[Controls & Layout, Tuple2[String, Int]]
```

the first part of that type, `Controls & Layout`, is expressing exactly the capabilities the program requires to run.
We can therefore view tagless final as an approach to capability-passing.
Similarly, when we discussed dependency injection in @sec:di we saw that the core is simply passing dependencies to constructors or methods.
We can view dependencies as capabilities, and so the essence of capability-passing is dependency injection (or vice versa, if you prefer.)

If capability-passing really is this simple, why do we have a whole chapter devoted to it?
One reason is that there is a little bit more to capability-passing than just passing stuff around.
We'll get to that towards the end of the chapter.
More important, though, is the different mental model capability-passing provides.
This is where we'll spend the majority of our time.
To illustrate this change in view we'll build a simple user interface toolkit using capability-passing style,
which we can compare to the one we created in @sec:tagless-final:aui using tagless final.
We'll see a different approach gives us a different outcome,
which will help to illustrate what we gain, and lose, with capability-passing style.
