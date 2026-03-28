#import "../../stdlib.typ": case-study
#case-study[Reactive Programming] <sec:case-study:reactive>

In this case study we will build a system for reactive programming.
This will bring together many of the programming strategies we've discussed,
and show how they can be used to drive both design and implementation.
We'll also see the critical importance of focusing on clear semantics in steering our approach.

We'll begin by describing reactive programming, and then move on to design and implementation. We cannot implement a complete system in this case study, so we'll finish with discussion of further extensions and the wider context of reactive programming that our case study sits within.


== Reactive Programming

*Reactive programming*, also known as *stream processing*, is the problem of writing programs that react to data as it becomes available. Many programs fit this model. For example, in a user interface we want to respond immediately to input events, such as mouse clicks and key presses. One a server we want to respond to network packets as they become available.

Callbacks and mutable state are one approach to reactive programming. This is not the path we'll take for the reasons discussed in @sec:what-is-fp: we value composition and reasoning, and callbacks provide neither. So what path will we take? The case study is, of course, the answer to this question, but before moving on I want to encourage you to pay attention to the process that leads to the code, not just the code itself. The process uses the design strategies, and is the most valuable part of the case study. Reactive programming may not be a problem you face, and if it is there are mature libraries you can use. The process, however, is reusable across programming problems.
