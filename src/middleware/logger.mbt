// Logger Middleware
//
// Logs HTTP requests in various formats.
// Default format: dev (METHOD /path STATUS time)

// ============================================================================
// Logger Configuration
// ============================================================================

///|
/// Log output format
pub enum LogFormat {
  /// Development format: GET /path 200 12ms
  Dev
  /// Combined log format (Apache-style)
  Combined
  /// JSON format for structured logging
  Json
}

///|
/// Logger configuration
pub struct LoggerConfig {
  /// Output format
  format : LogFormat
  /// Skip logging for certain requests
  skip : ((MwRequest) -> Bool)?
  /// Log to custom function (default: console.log)
  log_fn : ((String) -> Unit)?
}

///|
/// Default logger configuration
pub fn LoggerConfig::default() -> LoggerConfig {
  { format: LogFormat::Dev, skip: None, log_fn: None }
}

///|
/// Create dev format config
pub fn LoggerConfig::dev() -> LoggerConfig {
  { format: LogFormat::Dev, skip: None, log_fn: None }
}

///|
/// Create combined format config
pub fn LoggerConfig::combined() -> LoggerConfig {
  { format: LogFormat::Combined, skip: None, log_fn: None }
}

///|
/// Create JSON format config
pub fn LoggerConfig::json() -> LoggerConfig {
  { format: LogFormat::Json, skip: None, log_fn: None }
}

///|
/// Set skip function
pub fn LoggerConfig::with_skip(
  self : LoggerConfig,
  skip : (MwRequest) -> Bool,
) -> LoggerConfig {
  { ..self, skip: Some(skip) }
}

///|
/// Set custom log function
pub fn LoggerConfig::with_log_fn(
  self : LoggerConfig,
  log_fn : (String) -> Unit,
) -> LoggerConfig {
  { ..self, log_fn: Some(log_fn) }
}

// ============================================================================
// Logger Middleware
// ============================================================================

///|
/// Create logger middleware with default config (dev format)
pub fn logger() -> Middleware {
  logger_with_config(LoggerConfig::default())
}

///|
/// Create logger middleware with custom config
pub fn logger_with_config(config : LoggerConfig) -> Middleware {
  Middleware(async fn(ctx) {
    // Check skip condition
    match config.skip {
      Some(skip_fn) => if skip_fn(ctx.request) { return Continue(ctx) }
      None => ()
    }

    // Get current time
    let start_time = now_ms()

    // Format log message
    let message = format_log_message(ctx.request, start_time, config.format)

    // Output log
    match config.log_fn {
      Some(log_fn) => log_fn(message)
      None => console_log(message)
    }
    Continue(ctx)
  })
}

// ============================================================================
// Log Formatting
// ============================================================================

///|
fn format_log_message(
  request : MwRequest,
  start_time : Float,
  format : LogFormat,
) -> String {
  match format {
    Dev => format_dev(request, start_time)
    Combined => format_combined(request, start_time)
    Json => format_json(request, start_time)
  }
}

///|
/// Dev format: GET /path
fn format_dev(request : MwRequest, _start_time : Float) -> String {
  let m = request.http_method
  let path = request.path
  "\{m} \{path}"
}

///|
/// Combined format: IP - - [timestamp] "METHOD /path" status size "referer" "user-agent"
fn format_combined(request : MwRequest, _start_time : Float) -> String {
  let m = request.http_method
  let path = request.path
  let user_agent = request.get_header("User-Agent").unwrap_or("-")
  let referer = request.get_header("Referer").unwrap_or("-")
  let timestamp = get_timestamp()
  "- - - [\{timestamp}] \"\{m} \{path}\" - - \"\{referer}\" \"\{user_agent}\""
}

///|
/// JSON format: {"method": "GET", "path": "/", "timestamp": "..."}
fn format_json(request : MwRequest, _start_time : Float) -> String {
  let m = request.http_method
  let path = request.path
  let timestamp = get_timestamp()
  "{\"method\":\"\{m}\",\"path\":\"\{path}\",\"timestamp\":\"\{timestamp}\"}"
}

// ============================================================================
// FFI Helpers
// ============================================================================

///|
extern "js" fn now_ms() -> Float =
  #| () => Date.now()

///|
extern "js" fn get_timestamp() -> String =
  #| () => new Date().toISOString()

///|
extern "js" fn console_log(message : String) -> Unit =
  #| (msg) => console.log(msg)
