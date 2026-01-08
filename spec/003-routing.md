# ADR-003: URLPattern-Based Type-Safe Routing

## Status

Accepted

## Context

Routing systems have trade-offs:

1. **String patterns**: Flexible but error-prone
2. **File-based**: Implicit but inflexible
3. **Type-safe**: Explicit but verbose

Web platform now has URLPattern API:
- Standard browser/Deno API
- Powerful pattern matching
- Named groups for parameters

## Decision

Use URLPattern for route definitions with type-safe parameter extraction.

### Route Definition

```moonbit
pub struct Route {
  pattern: String              // URLPattern syntax
  handler: (Context) -> Response
  methods: Array[HttpMethod]
}
```

### Pattern Syntax

```
/users/:id          → { id: "123" }
/posts/:slug+       → { slug: "a/b/c" }
/files/*            → wildcard match
/api/v:version/... → { version: "2" }
```

### Route Registration

```moonbit
let routes = [
  Route::new("/", home_handler),
  Route::new("/posts/:slug", post_handler),
  Route::new("/api/*", api_handler),
]
```

### Parameter Extraction

```moonbit
pub fn Context::param(self, name: String) -> String?
pub fn Context::params(self) -> Map[String, String]
```

### Route Matching

```moonbit
pub fn match_route(url: String, routes: Array[Route]) -> Route?
```

Priority:
1. Exact matches first
2. Then parametric routes
3. Finally wildcards

## Consequences

### Positive

- **Standards-based**: URLPattern is web standard
- **Powerful**: Complex patterns supported
- **Type extraction**: Parameters are typed
- **Familiar**: Similar to Express patterns

### Negative

- **Browser support**: Needs polyfill in some browsers
- **Learning curve**: URLPattern syntax nuances
- **No compile-time validation**: Patterns are strings

### Neutral

- Can generate OpenAPI from routes
- Supports both SSR and API routes
