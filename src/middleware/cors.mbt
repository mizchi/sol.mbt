// CORS Middleware
//
// Cross-Origin Resource Sharing middleware with flexible configuration.

// ============================================================================
// CORS Configuration
// ============================================================================

///|
/// Origin configuration
pub enum CorsOrigin {
  /// Allow all origins (*)
  All
  /// Allow single origin
  Single(String)
  /// Allow multiple origins
  List(Array[String])
  /// Dynamic origin validation
  Dynamic((String) -> Bool)
}

///|
/// CORS configuration
pub struct CorsConfig {
  /// Allowed origins
  origin : CorsOrigin
  /// Allowed methods
  methods : Array[String]
  /// Allowed headers
  allowed_headers : Array[String]
  /// Exposed headers
  exposed_headers : Array[String]
  /// Allow credentials
  credentials : Bool
  /// Max age for preflight cache (seconds)
  max_age : Int?
}

///|
/// Default CORS configuration (permissive)
pub fn CorsConfig::default() -> CorsConfig {
  {
    origin: CorsOrigin::All,
    methods: ["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"],
    allowed_headers: ["Content-Type", "Authorization", "X-Requested-With"],
    exposed_headers: [],
    credentials: false,
    max_age: Some(86400), // 24 hours
  }
}

///|
/// Strict CORS configuration (same origin only)
pub fn CorsConfig::strict() -> CorsConfig {
  {
    origin: CorsOrigin::List([]),
    methods: ["GET", "POST"],
    allowed_headers: ["Content-Type"],
    exposed_headers: [],
    credentials: false,
    max_age: None,
  }
}

///|
/// Set allowed origin
pub fn CorsConfig::with_origin(
  self : CorsConfig,
  origin : CorsOrigin,
) -> CorsConfig {
  { ..self, origin, }
}

///|
/// Set single origin
pub fn CorsConfig::with_origin_single(
  self : CorsConfig,
  origin : String,
) -> CorsConfig {
  { ..self, origin: CorsOrigin::Single(origin) }
}

///|
/// Set allowed methods
pub fn CorsConfig::with_methods(
  self : CorsConfig,
  methods : Array[String],
) -> CorsConfig {
  { ..self, methods, }
}

///|
/// Set allowed headers
pub fn CorsConfig::with_allowed_headers(
  self : CorsConfig,
  headers : Array[String],
) -> CorsConfig {
  { ..self, allowed_headers: headers }
}

///|
/// Set exposed headers
pub fn CorsConfig::with_exposed_headers(
  self : CorsConfig,
  headers : Array[String],
) -> CorsConfig {
  { ..self, exposed_headers: headers }
}

///|
/// Enable credentials
pub fn CorsConfig::with_credentials(self : CorsConfig) -> CorsConfig {
  { ..self, credentials: true }
}

///|
/// Set max age
pub fn CorsConfig::with_max_age(self : CorsConfig, max_age : Int) -> CorsConfig {
  { ..self, max_age: Some(max_age) }
}

// ============================================================================
// CORS Middleware
// ============================================================================

///|
/// Create CORS middleware with default config
pub fn cors() -> Middleware {
  cors_with_config(CorsConfig::default())
}

///|
/// Create CORS middleware with custom config
pub fn cors_with_config(config : CorsConfig) -> Middleware {
  Middleware(async fn(ctx) {
    let origin_header = ctx.request.get_header("Origin")

    // No Origin header = same-origin request
    let origin = match origin_header {
      Some(o) => o
      None => return Continue(ctx)
    }

    // Validate origin
    let allowed = is_origin_allowed(origin, config.origin)
    if not(allowed) {
      return Continue(ctx) // Just don't add CORS headers
    }

    // Check if preflight request
    if ctx.request.http_method == "OPTIONS" {
      let response = build_preflight_response(origin, config)
      return Halt(response)
    }

    // Add CORS headers for actual request
    let ctx2 = add_cors_headers(ctx, origin, config)
    Continue(ctx2)
  })
}

// ============================================================================
// Origin Validation
// ============================================================================

///|
fn is_origin_allowed(origin : String, allowed : CorsOrigin) -> Bool {
  match allowed {
    All => true
    Single(allowed_origin) => origin == allowed_origin
    List(origins) => origins.contains(origin)
    Dynamic(check) => check(origin)
  }
}

// ============================================================================
// Response Building
// ============================================================================

///|
fn build_preflight_response(origin : String, config : CorsConfig) -> MwResponse {
  let headers : Array[(String, String)] = []

  // Access-Control-Allow-Origin
  let allow_origin = match config.origin {
    All => "*"
    _ => origin
  }
  headers.push(("Access-Control-Allow-Origin", allow_origin))

  // Access-Control-Allow-Methods
  let methods = join_array(config.methods, ", ")
  headers.push(("Access-Control-Allow-Methods", methods))

  // Access-Control-Allow-Headers
  if config.allowed_headers.length() > 0 {
    let allowed = join_array(config.allowed_headers, ", ")
    headers.push(("Access-Control-Allow-Headers", allowed))
  }

  // Access-Control-Allow-Credentials
  if config.credentials {
    headers.push(("Access-Control-Allow-Credentials", "true"))
  }

  // Access-Control-Max-Age
  match config.max_age {
    Some(age) => headers.push(("Access-Control-Max-Age", age.to_string()))
    None => ()
  }

  // Vary header
  headers.push(("Vary", "Origin"))
  { status: 204, headers, body: "", content_type: "text/plain" }
}

///|
fn add_cors_headers(
  ctx : MwContext,
  origin : String,
  config : CorsConfig,
) -> MwContext {
  let mut result = ctx

  // Access-Control-Allow-Origin
  let allow_origin = match config.origin {
    All => "*"
    _ => origin
  }
  result = result.add_header("Access-Control-Allow-Origin", allow_origin)

  // Access-Control-Allow-Credentials
  if config.credentials {
    result = result.add_header("Access-Control-Allow-Credentials", "true")
  }

  // Access-Control-Expose-Headers
  if config.exposed_headers.length() > 0 {
    let exposed = join_array(config.exposed_headers, ", ")
    result = result.add_header("Access-Control-Expose-Headers", exposed)
  }

  // Vary header
  result = result.add_header("Vary", "Origin")
  result
}

// ============================================================================
// Helper Functions
// ============================================================================

///|
fn join_array(arr : Array[String], separator : String) -> String {
  if arr.is_empty() {
    return ""
  }
  let buf = StringBuilder::new()
  for i, item in arr {
    if i > 0 {
      buf.write_string(separator)
    }
    buf.write_string(item)
  }
  buf.to_string()
}
