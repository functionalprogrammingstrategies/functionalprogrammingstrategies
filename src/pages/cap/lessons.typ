== Lessons from Capability-Passing

We've implemented a capability-passing user interface framework.
I certainly found it interesting, but we're unlikely to implement many such frameworks in our career, so the question becomes:
what are the reusable lessons?

Capability-passing is essentially a codata interpreter.
We still have a separation between description and action.
Programs, the description, are functions accepting capabilities.
Capabilities are interpreters.
We parameterize by capabilities, so we can swap in different implementations if we desire.
We don't usually parameterize by output type, which marks one difference with tagless final, though we could if we wanted.
In the improved encoding of tagless final, we saw how we could get type inference to infer all the dependencies.
This isn't possible with capability-passing, because we do not connect every program fragment with a combinator.
Instead we use direct-style code.
We lose the property of accumulating dependencies,
but unlike tagless final we don't need to use control flow combinators, like `map` and `flatMap`, to connect program fragments.
The code is simpler and uses the default language control flow.

Another big idea is shifting from values to effects.
With the interpreter strategy we build a program, and then run.
Previously these programs have been values.
Here the programs, the components and events in our user interface, are effects mediated by the capabilities.
Some capabilities provide want we usually consider effects: errors, asynchronicity, and so on.
What we've seen here is representing as effect what we usually think of as value: the layout tree and event graph.
Internally we're still building these data structure, but because they are internal to the capability context the user doesn't have to manage them.
This makes the programmer job a bit simpler.
We don't have to pass around the layout tree and event graph.
They disappear into the context, which makes the program easier to work with.

Built two structures: tree (layout tree) and graph (event graph).
Tree is straight-forward.
The tree structure reflects the structure of the call stack.
For the graph structure we reified the vertices of the graph and inferred the edges from usage.
We saw we can restrict the capabilities that are available to change the shape of the structure that can be built at given point.
For example, in leaf components we don't provide the layout capability so no more components can be added to the layout tree.
This could be more flexible.
For example, with a richer component hierarchy we might define buttons and drop down lists. Within the button component we'd allow text subcomponents, but not drop downs.
This is straightforward with capabilities, but not so easy with algebraic data types.
