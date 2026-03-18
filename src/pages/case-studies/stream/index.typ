#import "../../stdlib.typ": case-study
#case-study[Reactive Programming] <sec:case-study:reactive>

In this case study we will build a system for reactive programming. This will bring together many of the strategies we've previously seen.
We'll start by describing what we're going to build, and how we're going to approach building it.


== Reactive Programming

*Reactive programming*, also known as *stream processing*, is the problem of writing programs that react to data as it becomes available. Many programs fit this model. For example, in a user interface we want to respond immediately to input events, such as mouse clicks and key presses. Servers also fit this model: they respond to network packets as they become available.

Callbacks and mutable state are one approach to reactive programming. This is not the path we'll take for the reasons discussed in @sec:what-is-fp: we value composition and reasoning, and callbacks provide neither. So what path will we take? We answer this in detail in the next section, but before moving on I want encourage you to pay attention to the process behind the design, not just the design itself. The process uses the design strategies, and is the most valuable part of the case study to understand. Reactive programming may not be a problem you face, and if it is there are mature libraries you can use. The process, however, is reusable across programming problems.
