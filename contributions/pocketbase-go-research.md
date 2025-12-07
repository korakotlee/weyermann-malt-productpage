# PocketBase Go Customization Research

**Date**: 2024-12-07
**Latest Version**: v0.34.2
**Repository**: https://github.com/pocketbase/pocketbase

## Overview

PocketBase is designed to be extended with Go (not just JavaScript). When used as a Go framework, it provides a powerful hook system, custom routes, middleware patterns, and plugin architecture. This makes it ideal for building custom backends with type-safe Go code.

## Getting Started

### Minimal Example

```go
package main

import (
    "log"

    "github.com/pocketbase/pocketbase"
    "github.com/pocketbase/pocketbase/core"
)

func main() {
    app := pocketbase.New()

    // Add custom route
    app.OnServe().BindFunc(func(se *core.ServeEvent) error {
        se.Router.GET("/hello", func(re *core.RequestEvent) error {
            return re.String(200, "Hello world!")
        })
        return se.Next()
    })

    if err := app.Start(); err != nil {
        log.Fatal(err)
    }
}
```

### Build Commands

```bash
# Initialize module
go mod init myapp && go mod tidy

# Run in development
go run main.go serve

# Build static binary (no CGO required!)
CGO_ENABLED=0 go build
./myapp serve
```

## Hook System

PocketBase uses a **chain-of-responsibility** pattern for hooks. Every handler must call `e.Next()` to continue the chain.

### Core Hook Types

Located in `core/app.go`, the `App` interface defines 80+ hooks:

#### App Lifecycle Hooks
```go
OnBootstrap()    // App initialization
OnServe()        // Server start (add routes here)
OnTerminate()    // App shutdown
OnBackupCreate() // Backup creation
OnBackupRestore() // Backup restore
```

#### Model Hooks (Generic)
```go
OnModelValidate(tags ...string)  // Before/after validation
OnModelCreate(tags ...string)    // Before/after create
OnModelCreateExecute(tags ...string)
OnModelAfterCreateSuccess(tags ...string)
OnModelAfterCreateError(tags ...string)
OnModelUpdate(tags ...string)    // Before/after update
OnModelUpdateExecute(tags ...string)
OnModelAfterUpdateSuccess(tags ...string)
OnModelAfterUpdateError(tags ...string)
OnModelDelete(tags ...string)    // Before/after delete
OnModelDeleteExecute(tags ...string)
OnModelAfterDeleteSuccess(tags ...string)
OnModelAfterDeleteError(tags ...string)
```

#### Record Hooks (Typed for Records)
```go
OnRecordEnrich(tags ...string)   // Modify record before response
OnRecordValidate(tags ...string)
OnRecordCreate(tags ...string)
OnRecordUpdate(tags ...string)
OnRecordDelete(tags ...string)
// ... and more
```

#### Collection Hooks
```go
OnCollectionValidate(tags ...string)
OnCollectionCreate(tags ...string)
OnCollectionUpdate(tags ...string)
OnCollectionDelete(tags ...string)
```

#### API Request Hooks
```go
OnRecordAuthRequest(tags ...string)
OnRecordAuthWithPasswordRequest(tags ...string)
OnRecordAuthWithOAuth2Request(tags ...string)
OnRecordsListRequest(tags ...string)
OnRecordViewRequest(tags ...string)
OnRecordCreateRequest(tags ...string)
OnRecordUpdateRequest(tags ...string)
OnRecordDeleteRequest(tags ...string)
```

#### Other Hooks
```go
OnMailerSend()
OnRealtimeConnectRequest()
OnRealtimeMessageSend()
OnSettingsListRequest()
OnSettingsUpdateRequest()
OnFileDownloadRequest(tags ...string)
```

### Hook Handler Structure

From `tools/hook/hook.go`:

```go
type Handler[T Resolver] struct {
    Func     func(T) error  // Handler function
    Id       string         // Unique identifier (for removal)
    Priority int            // Execution order (lower = first)
}
```

### Binding Hooks

```go
// Simple bind with auto-generated ID
app.OnRecordCreate("posts").BindFunc(func(e *core.RecordEvent) error {
    // Do something before
    e.Record.Set("computed_field", "value")

    err := e.Next() // Continue chain

    // Do something after
    if err == nil {
        log.Println("Record created:", e.Record.Id)
    }

    return err
})

// Bind with custom ID and priority
app.OnServe().Bind(&hook.Handler[*core.ServeEvent]{
    Id:       "myCustomHandler",
    Priority: 999, // Execute last
    Func: func(e *core.ServeEvent) error {
        // Setup routes
        return e.Next()
    },
})

// Unbind by ID
app.OnServe().Unbind("myCustomHandler")
```

### Tagged Hooks

Tags filter hooks to specific collections:

```go
// Only triggers for "posts" collection
app.OnRecordCreate("posts").BindFunc(func(e *core.RecordEvent) error {
    return e.Next()
})

// Multiple collections
app.OnRecordUpdate("posts", "comments").BindFunc(func(e *core.RecordEvent) error {
    return e.Next()
})
```

## Custom Routes

### Route Registration

```go
app.OnServe().BindFunc(func(se *core.ServeEvent) error {
    // Simple route
    se.Router.GET("/api/custom", func(re *core.RequestEvent) error {
        return re.JSON(200, map[string]string{"status": "ok"})
    })

    // With path parameters
    se.Router.GET("/api/users/{id}", func(re *core.RequestEvent) error {
        id := re.Request.PathValue("id")
        return re.JSON(200, map[string]string{"id": id})
    })

    // Route groups
    api := se.Router.Group("/api/v2")
    api.GET("/items", listItems)
    api.POST("/items", createItem)
    api.PUT("/items/{id}", updateItem)
    api.DELETE("/items/{id}", deleteItem)

    return se.Next()
})
```

### HTTP Methods

```go
se.Router.GET(path, handler)
se.Router.POST(path, handler)
se.Router.PUT(path, handler)
se.Router.PATCH(path, handler)
se.Router.DELETE(path, handler)
se.Router.OPTIONS(path, handler)
se.Router.HEAD(path, handler)
se.Router.Route(method, path, handler) // Custom method
```

### RequestEvent Methods

```go
func handler(re *core.RequestEvent) error {
    // Access app
    app := re.App

    // Get authenticated user
    auth := re.Auth // *core.Record or nil

    // Request data
    body := re.Request.Body
    headers := re.Request.Header

    // Path parameters
    id := re.Request.PathValue("id")

    // Query parameters
    filter := re.Request.URL.Query().Get("filter")

    // Responses
    return re.String(200, "text response")
    return re.JSON(200, data)
    return re.HTML(200, "<h1>Hello</h1>")
    return re.Redirect(302, "/other")
    return re.NoContent(204)
    return re.FileFS(fsys, "file.txt")

    // Errors
    return re.BadRequestError("message", data)
    return re.UnauthorizedError("message", data)
    return re.ForbiddenError("message", data)
    return re.NotFoundError("message", data)
    return re.InternalServerError("message", err)
}
```

## Middleware

### Built-in Middlewares

From `apis/middlewares.go`:

```go
apis.RequireGuestOnly()     // Must NOT be authenticated
apis.RequireAuth()          // Must be authenticated (any collection)
apis.RequireAuth("users")   // Must be from specific collection
apis.RequireSuperuserAuth() // Must be superuser
apis.RequireSuperuserOrOwnerAuth("id") // Superuser or record owner
apis.RequireSameCollectionContextAuth("collection")
apis.SkipSuccessActivityLog() // Don't log successful requests
apis.BodyLimit(size)        // Limit request body size
apis.Gzip()                 // Gzip compression
apis.CORS(config)           // CORS handling
```

### Applying Middleware

```go
app.OnServe().BindFunc(func(se *core.ServeEvent) error {
    // To specific route
    se.Router.GET("/admin/stats", handler).Bind(apis.RequireSuperuserAuth())

    // To route group
    admin := se.Router.Group("/admin")
    admin.Bind(apis.RequireSuperuserAuth())
    admin.GET("/users", listUsers)
    admin.GET("/logs", listLogs)

    // Multiple middlewares
    se.Router.POST("/api/upload", uploadHandler).
        Bind(apis.RequireAuth()).
        Bind(apis.BodyLimit(10 << 20)) // 10MB

    return se.Next()
})
```

### Custom Middleware

```go
func RateLimitMiddleware(limit int) *hook.Handler[*core.RequestEvent] {
    return &hook.Handler[*core.RequestEvent]{
        Id:       "customRateLimit",
        Priority: -100, // Execute early
        Func: func(e *core.RequestEvent) error {
            // Check rate limit logic
            if isRateLimited(e.RealIP()) {
                return e.TooManyRequestsError("Rate limit exceeded", nil)
            }
            return e.Next()
        },
    }
}

// Usage
se.Router.GET("/api/data", handler).Bind(RateLimitMiddleware(100))
```

### Wrapping Standard Go Middleware

```go
// Wrap http.Handler
se.Router.GET("/legacy", apis.WrapStdHandler(legacyHandler))

// Wrap middleware func(http.Handler) http.Handler
se.Router.GET("/route", handler).BindFunc(
    apis.WrapStdMiddleware(someStdMiddleware),
)
```

## Plugin Pattern

From `plugins/migratecmd/migratecmd.go`:

```go
type Config struct {
    Dir         string
    Automigrate bool
    // ...
}

func MustRegister(app core.App, rootCmd *cobra.Command, config Config) {
    if err := Register(app, rootCmd, config); err != nil {
        panic(err)
    }
}

func Register(app core.App, rootCmd *cobra.Command, config Config) error {
    p := &plugin{app: app, config: config}

    // Add CLI command
    if rootCmd != nil {
        rootCmd.AddCommand(p.createCommand())
    }

    // Register hooks
    if p.config.Automigrate {
        p.app.OnCollectionCreateRequest().BindFunc(p.handler)
        p.app.OnCollectionUpdateRequest().BindFunc(p.handler)
    }

    return nil
}
```

## Cron Jobs

From `tools/cron/cron.go`:

```go
app.OnServe().BindFunc(func(se *core.ServeEvent) error {
    // Access the app's cron scheduler
    scheduler := se.App.Cron()

    // Add a job
    scheduler.MustAdd("dailyCleanup", "0 0 * * *", func() {
        // Runs at midnight every day
        log.Println("Running daily cleanup")
    })

    scheduler.MustAdd("everyHour", "0 * * * *", func() {
        // Runs at minute 0 of every hour
    })

    // Cron expression format: minute hour day month weekday
    // Supports: * (any), */n (every n), n-m (range), n,m (list)

    return se.Next()
})
```

## Database Operations

```go
// Find records
records, err := app.FindAllRecords("posts")
record, err := app.FindRecordById("posts", "abc123")
record, err := app.FindFirstRecordByData("users", "email", "test@example.com")

// Query builder
records, err := app.FindRecordsByFilter(
    "posts",
    "status = {:status} && author = {:author}",
    "-created", // sort
    10,         // limit
    0,          // offset
    dbx.Params{"status": "published", "author": userId},
)

// Create record
collection, _ := app.FindCollectionByNameOrId("posts")
record := core.NewRecord(collection)
record.Set("title", "Hello")
record.Set("content", "World")
err := app.Save(record)

// Update record
record.Set("title", "Updated")
err := app.Save(record)

// Delete record
err := app.Delete(record)

// Transactions
err := app.RunInTransaction(func(txApp core.App) error {
    // Use txApp for all operations
    record, _ := txApp.FindRecordById("posts", "abc")
    record.Set("views", record.GetInt("views")+1)
    return txApp.Save(record)
})

// Raw SQL
app.DB().NewQuery("SELECT * FROM posts WHERE id = {:id}").
    Bind(dbx.Params{"id": "abc"}).
    One(&result)
```

## Complete Example: Custom API

```go
package main

import (
    "log"
    "net/http"

    "github.com/pocketbase/pocketbase"
    "github.com/pocketbase/pocketbase/apis"
    "github.com/pocketbase/pocketbase/core"
    "github.com/pocketbase/pocketbase/tools/hook"
)

func main() {
    app := pocketbase.New()

    // Custom middleware
    authMiddleware := &hook.Handler[*core.RequestEvent]{
        Id: "customAuth",
        Func: func(e *core.RequestEvent) error {
            apiKey := e.Request.Header.Get("X-API-Key")
            if apiKey != "secret" {
                return e.UnauthorizedError("Invalid API key", nil)
            }
            return e.Next()
        },
    }

    // Hook: Modify records before response
    app.OnRecordEnrich("products").BindFunc(func(e *core.RecordEnrichEvent) error {
        // Add computed field
        price := e.Record.GetFloat("price")
        e.Record.Set("priceWithTax", price*1.1)
        return e.Next()
    })

    // Hook: Before record create
    app.OnRecordCreate("orders").BindFunc(func(e *core.RecordEvent) error {
        // Auto-set order number
        e.Record.Set("orderNumber", generateOrderNumber())
        return e.Next()
    })

    // Hook: After record create success
    app.OnRecordAfterCreateSuccess("orders").BindFunc(func(e *core.RecordEvent) error {
        // Send notification
        go sendOrderNotification(e.Record)
        return e.Next()
    })

    // Register routes
    app.OnServe().BindFunc(func(se *core.ServeEvent) error {
        // Public endpoint
        se.Router.GET("/api/health", func(re *core.RequestEvent) error {
            return re.JSON(http.StatusOK, map[string]bool{"healthy": true})
        })

        // Protected API group
        api := se.Router.Group("/api/v1")
        api.Bind(authMiddleware)

        api.GET("/stats", func(re *core.RequestEvent) error {
            count, _ := re.App.CountRecords("products")
            return re.JSON(http.StatusOK, map[string]int64{"products": count})
        })

        api.POST("/process", func(re *core.RequestEvent) error {
            var input struct {
                Data string `json:"data"`
            }
            if err := re.BindBody(&input); err != nil {
                return re.BadRequestError("Invalid input", err)
            }
            // Process...
            return re.JSON(http.StatusOK, map[string]string{"result": "processed"})
        })

        // Admin-only routes
        admin := se.Router.Group("/api/admin")
        admin.Bind(apis.RequireSuperuserAuth())
        admin.GET("/users", listAllUsers)

        return se.Next()
    })

    // Add cron job
    app.OnServe().BindFunc(func(se *core.ServeEvent) error {
        se.App.Cron().MustAdd("cleanup", "0 3 * * *", func() {
            log.Println("Running cleanup...")
        })
        return se.Next()
    })

    if err := app.Start(); err != nil {
        log.Fatal(err)
    }
}

func generateOrderNumber() string { return "ORD-" + time.Now().Format("20060102150405") }
func sendOrderNotification(r *core.Record) { /* ... */ }
func listAllUsers(re *core.RequestEvent) error { /* ... */ return nil }
```

## Key Files in Source

| File | Purpose |
|------|---------|
| `pocketbase.go` | Main PocketBase struct and initialization |
| `core/app.go` | App interface with all hook definitions |
| `core/base.go` | BaseApp implementation |
| `apis/base.go` | Router setup and default routes |
| `apis/middlewares.go` | Built-in middleware definitions |
| `tools/hook/hook.go` | Hook system implementation |
| `tools/router/router.go` | HTTP router wrapper |
| `tools/cron/cron.go` | Cron scheduler |
| `examples/base/main.go` | Reference implementation |

## Migration Files (Go)

```go
// migrations/1234567890_create_posts.go
package migrations

import (
    "github.com/pocketbase/pocketbase/core"
    m "github.com/pocketbase/pocketbase/migrations"
)

func init() {
    m.Register(func(app core.App) error {
        collection := core.NewBaseCollection("posts")
        collection.Fields.Add(&core.TextField{Name: "title", Required: true})
        collection.Fields.Add(&core.TextField{Name: "content"})
        return app.Save(collection)
    }, func(app core.App) error {
        collection, _ := app.FindCollectionByNameOrId("posts")
        return app.Delete(collection)
    })
}
```

## Useful Resources

- Official Docs: https://pocketbase.io/docs/go-overview/
- Go Package Docs: https://pkg.go.dev/github.com/pocketbase/pocketbase
- Source Code: https://github.com/pocketbase/pocketbase
- Examples: https://github.com/pocketbase/pocketbase/tree/master/examples
