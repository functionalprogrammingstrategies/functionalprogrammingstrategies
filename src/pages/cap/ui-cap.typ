#import "../stdlib.typ": href, styled-table
== User Interfaces as Capabilities

In the previous section we analyzed a typical user interface implementation and extracted three capabilities and spread across two stages.
We'll now turn to implementation, creating a framework for terminal user interfaces.


=== Infrastructure

We've already investigated the terminal in @sec:tagless-final:codata. Our usage here will be much more advanced, building full user interfaces, and as result we'll require more infrastructure. This code isn't particularly relevant to capability-passing, so we'll just quickly sketch it here. See the full code in the #href("https://github.com/functionalprogrammingstrategies/code")[code repository] for details.

The `Buffer` is the core type we'll use to display the interface. This is simply a two-dimensional array of characters representing what will appear on the screen. Each component should only write to a rectangular region of the terminal, and with the `Buffer` we can easily restrict them to the region they have been allocated. It's also much less error-prone to have a single type responsible for rendering than to delegate it to individual components.

The `Buffer` and related types. No styling (no bold, or underline, or blink, etc.) Only single character width, meaning no emojis or CJK characters.


`Component`.


=== Layout Capability

Layout is our first, and simplest, capability. There are two sides to this: the side that creates the layout tree, which is exposed to components, and the side that does layout, which is internal to the user interface runtime. Each side also corresponds to one of the two stages we identified earlier. We're disallowing dynamic changes to the layout tree, so construction belongs purely to the setup stage. Layout itself belongs to the reactive stage. This means components can change their size in response to events, but we cannot add or remove components from the tree.

We have a design principles to guide us: layout is an effect. Therefore an imperative interface will do.
Here's my implementation.

```scala
trait Layout:
  def addComponent(build: Component): Unit
```

This definition depends on a `Component` type that we have yet to implement.
Let's implement `Component` now.
It's reasonable to expect users to create their own compoments, so this should be codata rather than data.
Therefore we should think about the operations we want to perform on `Component`.
Two come to mind: measuring the size of the component, so that we can perform layout, and rendering it to the buffer once it is laid out.
This suggests the following interface.

```scala
trait Component:
  def size: Size

  def render(size: Size, buf: Buffer): Unit
```




=== Event Capability


=== Reactive Capability


=== An Example TUI


=== Limitations and Future Work

Our system is limited in many ways. Removing some of these limitations, such as the restriction on styling, is a straightforward change. We'll only address here the changes that require interesting architectural changes.

We made the conscious restriction that the layout cannot change once constructed. This is severe limitation.

Resource handling. Deregister handlers when a component is deleted.

Adding effects (in the Solid / React sense) to the reactive system.

The type system cannot prevent us capturing a capability and using it outside the scope when it is active. (Segue into next section.)
