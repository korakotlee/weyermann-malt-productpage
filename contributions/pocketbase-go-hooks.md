# PocketBase Go Hooks Reference

**Version**: v0.34.2
**Source**: `.tmp/pocketbase-src`

## Hook System Overview

PocketBase uses a **chain-of-responsibility** pattern. Every handler MUST call `e.Next()` to continue the chain.

### Hook Handler Structure

From `tools/hook/hook.go`:

```go
type Handler[T Resolver] struct {
    Func     func(T) error  // Handler function (required)
    Id       string         // Unique ID for removal (auto-generated if empty)
    Priority int            // Execution order (lower = first, default 0)
}
```

### Binding Methods

```go
// Simple - auto ID, priority 0
app.OnServe().BindFunc(func(e *core.ServeEvent) error {
    return e.Next()
})

// Full control - custom ID and priority
app.OnServe().Bind(&hook.Handler[*core.ServeEvent]{
    Id:       "myHandler",
    Priority: 999,  // Execute last
    Func: func(e *core.ServeEvent) error {
        return e.Next()
    },
})

// Remove by ID
app.OnServe().Unbind("myHandler")
```

---

## OnServe Hook

**Purpose**: Register custom routes and middleware when the server starts.

**Type**: `*hook.Hook[*core.ServeEvent]`

**Location**: `core/app.go:702`

### ServeEvent Properties

```go
type ServeEvent struct {
    hook.Event
    App           core.App
    Router        *router.Router[*core.RequestEvent]
    Server        *http.Server
    CertManager   *autocert.Manager
    Listener      net.Listener      // Can override
    InstallerFunc InstallerFunc     // Can override
}
```

### Example: Add Custom Routes

```go
app.OnServe().BindFunc(func(se *core.ServeEvent) error {
    // Simple route
    se.Router.GET("/api/hello", func(re *core.RequestEvent) error {
        return re.JSON(200, map[string]string{"message": "Hello!"})
    })

    // Route with parameters
    se.Router.GET("/api/users/{id}", func(re *core.RequestEvent) error {
        id := re.Request.PathValue("id")
        return re.JSON(200, map[string]string{"id": id})
    })

    // Route group with middleware
    api := se.Router.Group("/api/v1")
    api.Bind(apis.RequireAuth())
    api.GET("/profile", getProfile)
    api.POST("/items", createItem)

    return se.Next()  // REQUIRED!
})
```

### Example: From examples/base/main.go

```go
// Static file serving with priority 999 (runs last)
app.OnServe().Bind(&hook.Handler[*core.ServeEvent]{
    Func: func(e *core.ServeEvent) error {
        if !e.Router.HasRoute(http.MethodGet, "/{path...}") {
            e.Router.GET("/{path...}", apis.Static(os.DirFS(publicDir), indexFallback))
        }
        return e.Next()
    },
    Priority: 999,
})
```

---

## OnRecordCreate Hook

**Purpose**: Execute logic before/after a record is created.

**Type**: `*hook.TaggedHook[*RecordEvent]`

**Location**: `core/app.go:1009`

### RecordEvent Properties

```go
type RecordEvent struct {
    hook.Event
    App    core.App
    Record *core.Record  // The record being created
}
```

### Tags (Optional Filtering)

```go
// All collections
app.OnRecordCreate().BindFunc(handler)

// Specific collection
app.OnRecordCreate("posts").BindFunc(handler)

// Multiple collections
app.OnRecordCreate("posts", "comments").BindFunc(handler)
```

### Example: Before Create

```go
app.OnRecordCreate("orders").BindFunc(func(e *core.RecordEvent) error {
    // Modify record BEFORE save
    e.Record.Set("orderNumber", generateOrderNumber())
    e.Record.Set("status", "pending")
    e.Record.Set("createdBy", getAuthUserId(e))

    return e.Next()  // Continue to save
})
```

### Example: After Create

```go
app.OnRecordCreate("orders").BindFunc(func(e *core.RecordEvent) error {
    err := e.Next()  // Save first

    if err == nil {
        // Record was saved successfully
        go sendNotification(e.Record)
        log.Printf("Order created: %s", e.Record.Id)
    }

    return err
})
```

### Example: Validation

```go
app.OnRecordCreate("users").BindFunc(func(e *core.RecordEvent) error {
    email := e.Record.GetString("email")

    if !isValidEmail(email) {
        return apis.NewBadRequestError("Invalid email format", nil)
    }

    return e.Next()
})
```

---

## Related Record Hooks

### Create Lifecycle

```go
// Before validation & INSERT
app.OnRecordCreate("posts").BindFunc(...)

// After validation, before INSERT
app.OnRecordCreateExecute("posts").BindFunc(...)

// After successful INSERT (transaction committed)
app.OnRecordAfterCreateSuccess("posts").BindFunc(...)

// After failed INSERT
app.OnRecordAfterCreateError("posts").BindFunc(...)
```

### API Request Hook

```go
// Triggered on API POST /api/collections/{collection}/records
app.OnRecordCreateRequest("posts").BindFunc(func(e *core.RecordRequestEvent) error {
    // e.Record - the record being created
    // e.Request - HTTP request
    // e.Response - HTTP response
    return e.Next()
})
```

---

## Complete Example

```go
package main

import (
    "log"
    "github.com/pocketbase/pocketbase"
    "github.com/pocketbase/pocketbase/apis"
    "github.com/pocketbase/pocketbase/core"
    "github.com/pocketbase/pocketbase/tools/hook"
)

func main() {
    app := pocketbase.New()

    // === OnRecordCreate: Auto-populate fields ===
    app.OnRecordCreate("posts").BindFunc(func(e *core.RecordEvent) error {
        e.Record.Set("slug", slugify(e.Record.GetString("title")))
        e.Record.Set("views", 0)
        return e.Next()
    })

    // === OnRecordCreate: Validation ===
    app.OnRecordCreate("comments").BindFunc(func(e *core.RecordEvent) error {
        content := e.Record.GetString("content")
        if len(content) < 10 {
            return apis.NewBadRequestError("Comment too short", nil)
        }
        return e.Next()
    })

    // === OnRecordAfterCreateSuccess: Side effects ===
    app.OnRecordAfterCreateSuccess("orders").BindFunc(func(e *core.RecordEvent) error {
        go sendOrderConfirmation(e.Record)
        return e.Next()
    })

    // === OnServe: Custom routes ===
    app.OnServe().BindFunc(func(se *core.ServeEvent) error {
        // Public health check
        se.Router.GET("/health", func(re *core.RequestEvent) error {
            return re.JSON(200, map[string]bool{"ok": true})
        })

        // Protected admin routes
        admin := se.Router.Group("/admin")
        admin.Bind(apis.RequireSuperuserAuth())
        admin.GET("/stats", getStats)

        return se.Next()
    })

    // === OnServe: Static files (low priority) ===
    app.OnServe().Bind(&hook.Handler[*core.ServeEvent]{
        Id:       "staticFiles",
        Priority: 999,
        Func: func(e *core.ServeEvent) error {
            e.Router.GET("/{path...}", apis.Static(os.DirFS("./public"), true))
            return e.Next()
        },
    })

    if err := app.Start(); err != nil {
        log.Fatal(err)
    }
}
```

---

## Key Source Files

| File | Purpose |
|------|---------|
| `core/app.go` | Hook interface definitions (80+ hooks) |
| `core/base.go` | Hook implementations |
| `tools/hook/hook.go` | Hook/Handler structs |
| `apis/serve.go` | OnServe trigger location |
| `examples/base/main.go` | Reference implementation |

---

## Common Patterns

### 1. Always Call e.Next()
```go
// WRONG - breaks the chain
app.OnServe().BindFunc(func(e *core.ServeEvent) error {
    e.Router.GET("/api", handler)
    return nil  // Missing e.Next()!
})

// CORRECT
app.OnServe().BindFunc(func(e *core.ServeEvent) error {
    e.Router.GET("/api", handler)
    return e.Next()
})
```

### 2. Before vs After Pattern
```go
app.OnRecordCreate().BindFunc(func(e *core.RecordEvent) error {
    // BEFORE: Runs before record is saved
    e.Record.Set("field", "value")

    err := e.Next()  // Record saves here

    // AFTER: Runs after record is saved
    if err == nil {
        log.Println("Record saved:", e.Record.Id)
    }

    return err
})
```

### 3. Priority for Execution Order
```go
// Runs first (lower priority)
app.OnServe().Bind(&hook.Handler[*core.ServeEvent]{
    Priority: -100,
    Func: setupMiddleware,
})

// Runs last (higher priority)
app.OnServe().Bind(&hook.Handler[*core.ServeEvent]{
    Priority: 999,
    Func: setupFallbackRoutes,
})
```
