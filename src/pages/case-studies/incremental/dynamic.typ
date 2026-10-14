== Dynamic Dependencies

We've dodged `flatMap`. We'll now address it. What makes `flatMap` hard? It introduces dynamic dependencies. A signal may not always be a dependency of another signal.

Subscribers and unsubscribe.
