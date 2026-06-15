== User Interfaces as Capabilities

In the previous section we analyzed a typical user interface implementation and extracted three capabilities and spread across two stages.
We'll now turn to implementation, creating a framework for terminal user interfaces.


=== Infrastructure

We've already investigated the terminal in @sec:tagless-final:codata. Our usage here will be much more advanced, building full user interfaces, and as result we'll require more infrastructure. This code isn't particularly relevant to capability-passing, so we'll just quickly sketch it here. See the full code in the code repository *link here* for details.

The `Buffer` and related types. No styling (no bold, or underline, or blink, etc.) Only single character width, meaning no emojis or CJK characters.


`Component`.


=== Layout Capability


=== Event Capability


=== Reactive Capability


=== An Example TUI


=== Limitations and Future Work

Our system is limited in many ways. Removing some of these limitations, such as the restriction on styling, is a straightforward change. We'll only address here the changes that require interesting architectural changes.

We made the conscious restriction that the layout cannot change once constructed. This is severe limitation.

Resource handling. Deregister handlers when a component is deleted.

Adding effects (in the Solid / React sense) to the reactive system.

The type system cannot prevent us capturing a capability and using it outside the scope when it is active. (Segue into next section.)
