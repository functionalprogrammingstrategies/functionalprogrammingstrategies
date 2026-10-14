== Implementation

We will take a codata approach to implementation.

What is the API:

- get (tracking dependencies; needs context)
- peek (not tracking)
- set (root nodes only)

Implement. Nodes need to know their dependencies: upstream or downstream
depending on pull or push.

In reactive programming we solve this by constructing the dependency graph explicitly.

Solve by capturing a thunk. Rerun the thunk. Pull based. Evalutes only when
needed. Not needed = not evaluated. Still does more work than
necessary. How to make more efficient?

No effects (we'll get back to this eventually). This means we can cache and only
reevalute when a value changes. Dirty bit (stale). Needs to be transitive
property. If a node is stale all downstream nodes are stale. Thunks implicitly
hold upstream references. Need explicit downstream references. Listeners and context.

Dependencies can change dynamically. E.g. `if`. Need to tell upstream to unsubscribe listeners.

Push / pull and eager / lazy

Effects. Something needs to run every time a dependency changes, not just when
it is needed. Eager counterpart to lazy signals.

Codata and context. Codata we can represent dependencies as thunks. Don't need
to build an elaborate reification. Cannot explicitly walk the expression tree,
so must pass around context.
