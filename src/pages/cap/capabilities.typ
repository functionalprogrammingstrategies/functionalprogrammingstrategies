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
One of the goals of effect handlers is to surface the effects of a function,
so we can tell at a glance if calling that function is something to pay extra attention to.


=== Capabilities

A capability is something that provides the ability to carry out an effect.
For example, in Scala we can think of an `ExecutionContext` as providing the capability to execute asynchronously.
We can define context as the set of available capabilities along with the state of any resources that the capabilities control.

What we choose to define as a capability is a design decision.
It comes down to what we want to explicitly track and control access to.
For example, in many cases we do not consider memory allocation to a be a capability,
and code can freely allocate memory.
However, in systems programming we usually want to track and restrict memory allocation,
and therefore it would be considered a capability in this situation.

Capability-passing is simply the idea that programs explicitly declare the capabilities they require,
and we pass in those capabilities when we run them.
There is a bit more complexity to make everything work nicely, but really the core idea is that simple.
This is exactly what tagless final does, which we met in @sec:tagless-final.
When we wrote a program in tagless final style, and created a program with a type like

```scala
Program[Controls & Layout, Tuple2[String, Int]]
```

the first part of that type, `Controls & Layout`, is expressing exactly the capabilities the program requires to run.
Therefore, we can view tagless final as an approach to capability-passing.
Similarly, when we discussed dependency injection in @sec:di we saw that the core is simply passing dependencies to constructors or methods.
We can view dependencies as capabilities, and so the essence of capability-passing is dependency injection (or vice versa, if you prefer.)

If capability-passing really is this simple, why do we have a whole chapter devoted to it?
One reason is that there is a little bit more to capability-passing than just passing stuff around.
We'll get to that towards the end of the chapter.
More important, though, is the different mental model capability-passing provides.
This is where we'll spend the majority of our time.
We'll build a simple user interface toolkit using capability-passing style,
which we can compare to the one we created in @sec:tagless-final:aui using tagless final.
We'll see a slightly different approach gives us a different outcome.
