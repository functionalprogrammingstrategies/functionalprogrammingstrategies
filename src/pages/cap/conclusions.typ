#import "../stdlib.typ": narrative-cite
== Conclusions <sec:cap:conclusions>

*Overview of chapter here.*

This chapter has drawn together ideas from a number of fields: effect systems, object-capabilities, reactive systems, and user interfaces.
As usual I'm going to give a brief overview of the work in these fields, aiming to sketch out the connections as I understand them rather than give a comprehensive overview.

#narrative-cite(<brachthäuser22:cps>) is a very readable introduction to the capability-passing approach. I particularly like that it spends some time relating the work to object-oriented techniques, which should make it a bit more approachable to the typical programmer.

Effect systems, effect handlers, and algebraic effects.

ZIO and Kyo as existing effect systems that also have some notion of capability-passing. Written in monadic style, not direct style. No integration with capture checking.

Coeffects

Object-capabilities.

In this chapter we introduced reactive programming. The core ideas are very old (Esterel etc.) but the modern lineage starts, I believe, with functional reactive programming (FRP). Fran.

FrTime / Flapjax lineage. Glitch-free, web.

Observables / Rx lineage. Duality between observable and iterator. Tricky semantics (hot and cold observables, glitches) and large API.

Scala.React #cite(<maier12:deprecating>) has a `Signal` type that is remarkably similar in operation to the one we developed. This was surprising to me. I wasn't aware of Scala.React until after I had implemented my own system, and I thought the innovation of dynamically constructing the dependency graph had only come about later, in the Javascript frameworks. Scala.React inspired interesting later research bringing concurrent and distributed execution into the reactive model #cite(<salvaeschi14:rescala>) #cite(<drechsler18:thread-safe>) #cite(<kuessner23:ardt>).

Modern web systems. Knockout.js, S predecessors to current batch of Solid, Vue, Svelte, etc. Move away from the observable abstraction to signal: a time-varying value. Simpler to work with.

React hooks as effects and handlers. Dan Abramov's "Algebraic Effects for the Rest of Us", and Suspense's throw-a-promise trick is a hand-rolled effect handler.

#narrative-cite(<schuster16:reactive-variables>) presents a system where reactive variables are not reified, and as such are not first-class values and cannot escape the scope in which they are defined. The forces a simple shape on the event graph that makes updates easy. I think this restriction is too severe to be practical. For example, if we cannot pass a reactive variables around, we cannot usefully define components and hence the system cannot be modular. However it's interesting that capabilities in Effekt and Scala 3 have the same restriction on escaping their scope, but enforcing this via the type system allows capabilities to be reified. I see this as early works that points in the direction of the system we ended up implementing.

Finally, I mentioned that many existing user interfaces frameworks can be viewed as capability-passing systems. This applies to the modern Javascript frameworks I already mentioned. They all have some notion of context—or capability—in which execution takes place.
Jetpack Compose compiler adds `Composer` context parameter. That's the capability right there!
Immediate mode GUIs are all capability-passing, which is explicit in the egui case.
