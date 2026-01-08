# ADR-001: SSR Framework with Hono Integration

## Status

Accepted

## Context

Server-side rendering requires:

1. **HTTP handling**: Request/response processing
2. **Routing**: URL to handler mapping
3. **Rendering**: VNode to HTML string conversion
4. **State management**: Server-side data fetching

Options for HTTP framework:
- Express.js: Legacy, callback-based
- Fastify: Performance-focused, schema validation
- Hono: Lightweight, edge-compatible, TypeScript-first

## Decision

Build Sol on top of Hono for HTTP handling, with Luna for rendering.

### Architecture

```
Request → Hono Router → Sol Handler → Luna Render → Response
```

### Handler Definition

```moonbit
pub fn handler(c: Context) -> Response {
  let data = fetch_data()
  let vnode = page_component(data)
  let html = render_to_string(vnode)
  c.html(html)
}
```

### Hono Integration

```typescript
import { Hono } from 'hono'
import { solMiddleware } from '@luna_ui/sol'

const app = new Hono()
app.use('*', solMiddleware())
app.get('/', (c) => moonbitHandler(c))
```

### Middleware Stack

1. **Static assets**: Serve from public/
2. **Sol middleware**: Island hydration setup
3. **Route handlers**: Page rendering
4. **Error handling**: Graceful error pages

## Consequences

### Positive

- **Edge-ready**: Hono works on Cloudflare, Deno, etc.
- **Lightweight**: Minimal runtime overhead
- **Type-safe**: Full TypeScript/MoonBit types
- **Familiar**: Express-like middleware pattern

### Negative

- **JavaScript dependency**: Hono is JS, not pure MoonBit
- **Two runtimes**: MoonBit WASM + JS interop
- **Learning curve**: Must understand both ecosystems

### Neutral

- Similar architecture to Remix, SvelteKit
- Can swap Hono for other frameworks if needed
