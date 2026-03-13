== Effect Systems and Dependency Injection

TODO: Introduction. The previous sections treated requiring and providing as separate concerns. Effect systems bring them together into a unified framework. We can understand effect systems as a refinement of tagless final, and effect handlers as interpreters in the sense of @sec:interpreters. This section is more theoretical and forward-looking; the goal is to situate effect systems within the DI landscape rather than to teach a specific library or language feature.


=== From Tagless Final to Effect Systems

TODO: Recall the tagless final pattern's key move: abstract over `F[_]` and require algebra instances as `given` parameters. The limitations this creates---needing to thread `F[_]` everywhere, composing multiple algebras, the awkwardness of monad transformers when effects combine. Effect systems address these limitations by replacing the higher-kinded type parameter with an *effect row*: a type-level description of which effects a computation may perform. Show the structural parallel between a tagless final signature and an effectful signature.


=== Capabilities as Dependencies

TODO: In capability-based effect systems (including Scala 3's `CanThrow` and the broader capabilities model), an effect is represented as a capability value that must be in scope for the effect to be performed. Holding a capability is exactly holding a dependency. Providing a capability at the program boundary is exactly providing a dependency via `using`. Show the connection to the `using`-based approach from the providing section, and note that capabilities make the dependency relationship visible in types.


=== Effect Handlers as Interpreters

TODO: In algebraic effect systems, effect handlers play the same role as interpreters in the interpreter strategy (@sec:interpreters). The program describes what effects it wants to perform---it is a description, like a DSL program. The handler provides the implementation---it is the interpreter, and it is where dependencies live. This gives the cleanest separation of the two facets of DI: requiring (the effect types in the program's signature) and providing (the handlers applied at the boundary). Connect back to the staged programming view of interpreters from @sec:di:interpreters.
