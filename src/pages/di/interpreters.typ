== Interpreters as Staged Dependency Injection <sec:di:interpreters>

We have seen the interpreter strategy, first introduced in @sec:interpreters, as one of the main ways of structuring programs.
Remember that in the interpreter strategy we divide the code into the program, which describes what we want to do, and the interpreter, which carries out the actions in the description.
The interpreter strategy also provides a nice approach to dependency injection, and the key insight is one of *staging*: the program and the interpreter run at different times, and dependencies need only be present at the later stage.


=== Interpreters as Staged Computation

TODO: Explain the staging view. Writing the program is one stage; running it via an interpreter is a later stage. Dependencies belong to the later stage. The program author is freed from needing to know about or thread dependencies; the interpreter author is responsible for wiring them. Contrast with constructor injection and the reader monad, where dependencies must be present throughout.


=== Dependencies in the Interpreter

TODO: Show with an example (e.g. a query language or simple command DSL) that the program itself has no dependency parameters, while the interpreter that executes it takes all necessary dependencies. The DSL user writes clean, dependency-free code. The interpreter author does the wiring once.


=== Trade-offs

TODO: The staging view is powerful but not free. We must commit to the interpreter structure, which requires the program to be represented as a value (a data structure or similar). Not all code is naturally expressed this way. However, when it fits, the separation is very clean.

