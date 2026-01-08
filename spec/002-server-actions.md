# ADR-002: Server Actions with Progressive Enhancement

## Status

Accepted

## Context

Form handling in modern web apps needs:

1. **Server processing**: Validate and persist data
2. **Progressive enhancement**: Work without JavaScript
3. **CSRF protection**: Prevent cross-site attacks
4. **Optimistic UI**: Fast feedback to users

Traditional approaches:
- API routes + fetch: Requires JavaScript
- Form POST + redirect: Works without JS but poor UX
- Server Actions (Next.js): Best of both worlds

## Decision

Implement Server Actions that work with and without JavaScript.

### Action Definition

```moonbit
pub fn create_action(handler: (FormData) -> ActionResult) -> Action

pub enum ActionResult {
  Success(data: Json)
  Redirect(url: String)
  Error(message: String)
}
```

### HTML Form Integration

```html
<form method="POST" action="/_actions/submit-form">
  <input type="hidden" name="_csrf" value="...">
  <input name="email" type="email">
  <button type="submit">Subscribe</button>
</form>
```

### Progressive Enhancement

Without JavaScript:
1. Form submits via POST
2. Server processes action
3. Redirect to result page

With JavaScript:
1. Intercept form submit
2. Fetch to action endpoint
3. Update UI optimistically
4. Handle response

### CSRF Protection

```moonbit
pub fn generate_csrf_token() -> String
pub fn validate_csrf_token(token: String) -> Bool
```

- Token generated per session
- Embedded in hidden form field
- Validated on every action

## Consequences

### Positive

- **Works everywhere**: Graceful degradation
- **Secure by default**: CSRF protection built-in
- **Simple mental model**: Just forms + handlers
- **Type-safe**: MoonBit validates data

### Negative

- **Token management**: Must handle CSRF lifecycle
- **Hydration complexity**: Form state during hydration
- **Redirect handling**: Different behavior JS vs no-JS

### Neutral

- Similar to Remix actions
- Can extend to support file uploads
