// Sol Middleware - Railway Oriented Programming based middleware system
//
// Design principles:
// 1. Function pipeline: middlewares compose with `|>` and `then_`
// 2. Flow type for ROP: `Continue(ctx)` / `Halt(response)` controls flow
// 3. Immutable context: state changes return new context
// 4. Type-safe: middleware chains are type-checked

// ============================================================================
// Type Aliases
// ============================================================================

///|
/// Environment bindings (e.g., Cloudflare Workers KV)
pub type Env = Unit

///|
/// Execution context (e.g., Cloudflare Workers context)
pub type ExecutionContext = Unit

///|
/// Hono context type alias
pub type Ctx = @hono.Context[Env, ExecutionContext]

// ============================================================================
// Core Types
// ============================================================================

///|
/// Middleware processing result - Railway Oriented Programming
pub(all) enum Flow[T] {
  /// Continue to next middleware with updated context
  Continue(T)
  /// Halt pipeline and return response immediately
  Halt(MwResponse)
}

///|
/// HTTP Response from middleware
pub struct MwResponse {
  /// HTTP status code
  status : Int
  /// Response headers
  headers : Array[(String, String)]
  /// Response body
  body : String
  /// Content type (defaults to text/plain)
  content_type : String
}

///|
/// Create a text response
pub fn MwResponse::text(body : String, status? : Int) -> MwResponse {
  {
    status: status.unwrap_or(200),
    headers: [],
    body,
    content_type: "text/plain",
  }
}

///|
/// Create a JSON response
pub fn MwResponse::json(body : String, status? : Int) -> MwResponse {
  {
    status: status.unwrap_or(200),
    headers: [],
    body,
    content_type: "application/json",
  }
}

///|
/// Create an HTML response
pub fn MwResponse::html(body : String, status? : Int) -> MwResponse {
  {
    status: status.unwrap_or(200),
    headers: [],
    body,
    content_type: "text/html",
  }
}

///|
/// Create a redirect response
pub fn MwResponse::redirect(url : String, status? : Int) -> MwResponse {
  {
    status: status.unwrap_or(302),
    headers: [("Location", url)],
    body: "",
    content_type: "text/plain",
  }
}

///|
/// Create an unauthorized response
pub fn MwResponse::unauthorized(message? : String) -> MwResponse {
  {
    status: 401,
    headers: [],
    body: message.unwrap_or("Unauthorized"),
    content_type: "text/plain",
  }
}

///|
/// Create a forbidden response
pub fn MwResponse::forbidden(message? : String) -> MwResponse {
  {
    status: 403,
    headers: [],
    body: message.unwrap_or("Forbidden"),
    content_type: "text/plain",
  }
}

///|
/// Create a not found response
pub fn MwResponse::not_found(message? : String) -> MwResponse {
  {
    status: 404,
    headers: [],
    body: message.unwrap_or("Not Found"),
    content_type: "text/plain",
  }
}

///|
/// Create a bad request response
pub fn MwResponse::bad_request(message? : String) -> MwResponse {
  {
    status: 400,
    headers: [],
    body: message.unwrap_or("Bad Request"),
    content_type: "text/plain",
  }
}

///|
/// Add header to response
pub fn MwResponse::with_header(
  self : MwResponse,
  name : String,
  value : String,
) -> MwResponse {
  let headers = self.headers.copy()
  headers.push((name, value))
  { ..self, headers, }
}

// ============================================================================
// Request Information
// ============================================================================

///|
/// Immutable request information
pub struct MwRequest {
  /// HTTP method (GET, POST, etc.)
  http_method : String
  /// Request path
  path : String
  /// Request headers (as array of tuples for JS compatibility)
  headers : Array[(String, String)]
  /// Query parameters
  query : Array[(String, String)]
  /// Request URL
  url : String
}

///|
/// Get header value (case-insensitive)
pub fn MwRequest::get_header(self : MwRequest, name : String) -> String? {
  let lower_name = name.to_lower()
  for pair in self.headers {
    if pair.0.to_lower() == lower_name {
      return Some(pair.1)
    }
  }
  None
}

///|
/// Get query parameter
pub fn MwRequest::get_query(self : MwRequest, name : String) -> String? {
  for pair in self.query {
    if pair.0 == name {
      return Some(pair.1)
    }
  }
  None
}

// ============================================================================
// Middleware Context
// ============================================================================

///|
/// Immutable middleware context
pub struct MwContext {
  /// Original Hono context (internal use)
  ctx : Ctx
  /// Request information (read-only)
  request : MwRequest
  /// State shared between middlewares
  state : Map[String, @js.Any]
  /// Headers to add to response
  response_headers : Array[(String, String)]
}

///|
/// Create MwContext from Hono context
pub fn MwContext::from_ctx(ctx : Ctx) -> MwContext {
  let request = extract_request(ctx)
  { ctx, request, state: {}, response_headers: [] }
}

///|
/// Get state value by key
pub fn MwContext::get(self : MwContext, key : String) -> @js.Any? {
  self.state.get(key)
}

///|
/// Set state value (returns new context)
pub fn MwContext::set(
  self : MwContext,
  key : String,
  value : @js.Any,
) -> MwContext {
  let state = self.state
  state[key] = value
  { ..self, state, }
}

///|
/// Check if state has key
pub fn MwContext::has(self : MwContext, key : String) -> Bool {
  self.state.contains(key)
}

///|
/// Add response header (returns new context)
pub fn MwContext::add_header(
  self : MwContext,
  name : String,
  value : String,
) -> MwContext {
  let headers = self.response_headers.copy()
  headers.push((name, value))
  { ..self, response_headers: headers }
}

///|
/// Add multiple response headers (returns new context)
pub fn MwContext::add_headers(
  self : MwContext,
  headers : Array[(String, String)],
) -> MwContext {
  let new_headers = self.response_headers.copy()
  for h in headers {
    new_headers.push(h)
  }
  { ..self, response_headers: new_headers }
}

// ============================================================================
// FFI Helpers
// ============================================================================

///|
fn extract_request(ctx : Ctx) -> MwRequest {
  let http_method = ffi_get_method(ctx.as_any())
  let path = ffi_get_path(ctx.as_any())
  let url = ffi_get_url(ctx.as_any())
  let headers = ffi_get_headers(ctx.as_any())
  let query = ffi_get_query(ctx.as_any())
  { http_method, path, url, headers, query }
}

///|
extern "js" fn ffi_get_method(ctx : @js.Any) -> String =
  #| (c) => c.req.method

///|
extern "js" fn ffi_get_path(ctx : @js.Any) -> String =
  #| (c) => new URL(c.req.url).pathname

///|
extern "js" fn ffi_get_url(ctx : @js.Any) -> String =
  #| (c) => c.req.url

///|
extern "js" fn ffi_get_headers(ctx : @js.Any) -> Array[(String, String)] =
  #| (c) => {
  #|   const result = [];
  #|   c.req.raw.headers.forEach((v, k) => result.push({_0: k, _1: v}));
  #|   return result;
  #| }

///|
extern "js" fn ffi_get_query(ctx : @js.Any) -> Array[(String, String)] =
  #| (c) => {
  #|   const url = new URL(c.req.url);
  #|   return Array.from(url.searchParams.entries()).map(([k, v]) => ({_0: k, _1: v}));
  #| }
