== Capture Checking

Capture checking is one of the parts missing from the capability-passing story we've told so far.
Core idea: capabilities can only be used within the lexical scope where they are defined.
Capture checking prevents capabilities being used outside the scope where they are valid.

Example: capturing the layout capability and using it during the render phase when it's not valid (dynamically adding components.)
Explain how capture checking can solve this.

Fundamentally, capture checking extends the type system to reason about resources.
We can view this as another approach to indexed codata, which we met in @sec:indexed-types:codata.
The core idea is the same: we cannot call certain methods unless certain conditions are met.
The details are, however, different.
Indexed codata restricts which methods are callable based on type-level state reflecting the allowed protocol.
Cannot stop capturing / escape.
Capture checking restricts where values can flow.
Cannot express protocol: this method only after that method.
