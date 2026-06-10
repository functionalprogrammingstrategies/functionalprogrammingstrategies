== Lessons from Capability-Passing

We've implemented a capability-passing user interface framework.
I certainly found it interesting, but we're unlikely to implement many such frameworks in our career, so the question becomes:
what are the reusable lessons?

Capability-passing is essentially a codata interpreter.
We still have a separation between description and action.
Capabilities are interpreters.
We parameterize by capabilities, so we can swap in different implementations if we desire.
We don't usually parameterize by output type, which marks one difference with tagless final.
We lose the ability to get type inference to accumulate the required capabilities, like we saw with tagless final.
We gain direct-style code.
Unlike tagless final we don't need to use control-flow combinators, like `map` and `flatMap`, to connect program fragments.

Another big idea is shifting from values to effects.
With the interpreter strategy we build a program, and then run.
Previously these programs have been values.
Here the programs, the components and events, are effects mediated by the combinators.

Built two structures: tree (layout tree) and graph (event graph).
Tree is straight-forward.
The tree structure reflects the structure of the call stack.
For the graph structure we reified the vertices of the graph and inferred the edges from usage.
We saw we can restrict the capabilities that are available to change the shape of the structure that can be built at given point.
For example, in leaf components we don't provide the layout capability so no more components can be added to the layout tree.
This could be more flexible.
For example, with a richer component hierarchy we might define buttons and drop down lists. Within the button component we'd allow text subcomponents, but not drop downs.
This is straightforward with capabilities, but not so easy with algebraic data types.
