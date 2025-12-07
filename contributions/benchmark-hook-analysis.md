# PocketBase Hook System Analysis

PocketBase's hook system implements a **chain-of-responsibility pattern** using Go generics. The `Hook[T Resolver]` struct is thread-safe via `sync.RWMutex`. Each `Handler` has a `Func`, optional `Id`, and `Priority` (lower executes first).

Key methods: `Bind()` registers handlers with ID deduplication and priority sorting; `BindFunc()` is a convenience wrapper; `Unbind()` removes by ID; `Trigger()` builds a nested closure chain where each handler must call `e.Next()` to continue.

The clever reverse-iteration in `Trigger()` constructs the chain so handlers execute in priority order. One-off handlers can be appended at trigger time.
