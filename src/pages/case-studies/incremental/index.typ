#import "../../stdlib.typ": case-study
#case-study[Incremental Computing] <sec:case-study:incremental>

In this case study we will implement a form of *incremental computing*,
which is a type of program that automatically updates in response to change.
If you have used a spreadsheet,
where cells automatically update whenever a dependency changes,
then you have used incremental computing.

We'll begin by describing incremental computing, and constrasting it to reactive
programming which we met in @sec:case-study:reactive.
We will then implement for incremental computing.
We will finish by discussing applications and related work.


== Incremental Computing

You have probably used a spreadsheet.
A very typical thing in a spreadsheet is to define the value of one cell as depending on others.
For example, say we have defined two cells

```
A1 = 3
B1 = 5
```

and a third that depends on these two

```
C1 = A1 + B1
```

So far this is a program we could write in any programming language.
Interesting things happen when we change a value; let's say we change `A1` to `7`.
The spreadsheet will automatically recalculate every cell that depends on `A1`.
In this case that is `C1`.

We could rerun the entire program but that is both wasteful,
and dangerous if our program contains effects.
Better to just recompute what is needed.
This is the essence of incremental computing:
allowing values to change and recomputing their dependents,
and only their dependents, following change.

Reactive programming, which we met in @sec:case-study-reactive does a similar task.
What is the precise difference between them,
and when would we prefer one to the other?

Reactive computing considers variables as having a sequence of values ordered by time,
and allows us to perform operations that take account of time.
For example, we can fold over the history of values, perhaps to compute a moving average.
Or we might write a method that absorbs changes occuring within a small time window,
(useful for buttons, which many users will accidentally click twice in rapid succession.

Incremental computing is simpler.
We don't have access to the history of values.
At any given point in time a variable,
sometimes called a *signal* in incremental computing,
has a value.
When a value updates, whether due to an external event or a dependency changing,
that update is an atomic operation:
we cannot observe it and react to it like we can in reactive programming.

This simpler model allows incremental computing to be more ergonomic that reactive programming.
Reactive programming has a large API,
and requires the user to manually wire together the dependency graph.
As we will see, incremental computing has a very minimal API,
and we can infer the dependency graph from usage.

Incremental computing has found a home in user interfaces.
Much of a user interface driven by simple state.
For example, the user's settings might be open or closed.
Within the settings we might have a choice of a compact, normal, and spacious layout.
Changing a state should lead to a corresponding change in the user interface.
Each individual change is trivial, but managing them all together can be problem.
Incremental computing allows to express the dependencies of the user interface on the state,
and only recompute what we need to when the state changes.
