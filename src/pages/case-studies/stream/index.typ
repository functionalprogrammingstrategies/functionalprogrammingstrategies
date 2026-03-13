#import "../../stdlib.typ": case-study
#case-study[Reactive Programming] <sec:case-study:reactive>

In this case study we will build a system for reactive programming. This will bring together many of the strategies we've previously seen.
We'll start by describing what we're going to build, and how we're going to approach building it.


== Reactive Programming

*Reactive programming*, also known as *stream processing*, is the problem of writing programs that react to data as it becomes available. Many programs fit this model. For example, user interfaces, responding to user input events, are a natural application. So are servers responding to data as it arrives over the network.

Callbacks and mutable state are one approach to reactive programming. This is not the path we'll take for the reasons discussed in @sec:what-is-fp: we value composition and reasoning, and the callback-based approach to reactive programming provides neither. So how will we solve this problem? This case study will show this, but it's not the most important part of the case study. Reactive programming may not be a problem you face, and even if it is there are almost certainly mature libraries you can use. What you should pay attention to is the process we use to come to the solution; this is the knowledge that is reusable across programming problems. As you would expect, it involves applying the programming strategies we've learned so far.
