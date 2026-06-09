#import "../stdlib.typ": narrative-cite
== Conclusions <sec:cap:conclusions>

#narrative-cite(<brachthäuser22:cps>) is a very readable introduction to the capability-passing approach. I particularly like that it spends some time relating the work to object-oriented techniques, which should make it a bit more approachable to the typical programmer.


In this chapter we introduced reactive programming. This

#narrative-cite(<schuster16:reactive-variables>) presents a system where reactive variables are not reified, and as such are not first-class values and cannot escape the scope in which they are defined. The forces a simple shape on the event graph that makes updates easy. I think this restriction is too severe to be practical. For example, if we cannot pass a reactive variables around, we cannot usefully define components and hence the system cannot be modular. However it's interesting that capabilities in Effekt and Scala 3 have the same restriction on escaping their scope, but enforcing this via the type system allows capabilities to be reified. I see this as early works that points in the direction of the system we ended up implementing.
