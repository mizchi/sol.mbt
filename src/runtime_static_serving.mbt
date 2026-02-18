// Runtime static serving helpers

// Static File Serving
// ============================================================================

///|
extern "js" fn ffi_create_js_response(
  body : String,
  content_type : String,
) -> @http.Response =
  #| (body, contentType) => new Response(body, { headers: { 'Content-Type': contentType } })

///|
/// Create a response for static files with security headers
extern "js" fn ffi_create_static_response(
  body : String,
  content_type : String,
  cache_control : String,
) -> @http.Response =
  #| (body, contentType, cacheControl) => new Response(body, { headers: { 'Content-Type': contentType, 'X-Content-Type-Options': 'nosniff', 'Cache-Control': cacheControl } })

///|
extern "js" fn ffi_read_file_sync(path : String) -> String? =
  #| (path) => {
  #|   try {
  #|     if (!globalThis.__SOL_FS__) {
  #|       throw new Error('fs module not initialized. Call __SOL_INIT_FS__ first.');
  #|     }
  #|     return globalThis.__SOL_FS__.readFileSync(path, 'utf-8');
  #|   } catch (e) {
  #|     return undefined;
  #|   }
  #| }

///|
/// Create a text response with content type
pub fn text_response(body : String, content_type : String) -> @http.Response {
  ffi_create_js_response(body, content_type)
}

///|
/// Create a JavaScript response
pub fn js_response(body : String) -> @http.Response {
  ffi_create_js_response(body, "application/javascript")
}

///|
/// Create a static file response with security headers
pub fn static_response(
  body : String,
  content_type : String,
  cache_control? : String,
) -> @http.Response {
  let cache = cache_control.unwrap_or("max-age=3600")
  ffi_create_static_response(body, content_type, cache)
}

///|
/// Read file synchronously (for static file serving)
pub fn read_file_sync(path : String) -> String? {
  ffi_read_file_sync(path)
}

/// Static file configuration
pub struct StaticFileConfig {
  /// URL path prefix (e.g., "/static")
  path_prefix : String
  /// Local directory path (e.g., "static")
  local_dir : String
  /// File mappings: (url_filename, local_path)
  mappings : Array[(String, String)]
  /// Cache-Control header value (default: "max-age=3600", use "no-cache, no-store" for dev)
  cache_control : String
}

///|
/// Create default static file config for Luna apps
pub fn StaticFileConfig::default() -> StaticFileConfig {
  {
    path_prefix: "/static",
    local_dir: "static",
    mappings: [("loader.js", "static/loader.js")],
    cache_control: "max-age=3600",
  }
}

///|
/// Create static file config for development (no caching)
pub fn StaticFileConfig::dev() -> StaticFileConfig {
  {
    path_prefix: "/static",
    local_dir: "static",
    mappings: [("loader.js", "static/loader.js")],
    cache_control: "no-cache, no-store, must-revalidate",
  }
}

///|
/// Builder: add file mapping
pub fn StaticFileConfig::with_mapping(
  self : StaticFileConfig,
  url_filename : String,
  local_path : String,
) -> StaticFileConfig {
  let new_mappings = self.mappings.copy()
  new_mappings.push((url_filename, local_path))
  { ..self, mappings: new_mappings }
}

///|
/// Configuration for serving a static directory (SSG output)
pub(all) struct StaticDirServeConfig {
  /// URL path prefix (e.g., "/docs")
  path_prefix : String
  /// Local directory path (relative to cwd)
  local_dir : String
}

///|
/// Create default StaticDirServeConfig
pub fn StaticDirServeConfig::new(
  path_prefix : String,
  _source_dir : String,
) -> StaticDirServeConfig {
  // Map to .sol/prod/static/{path_prefix}
  let local_dir = ".sol/prod/static" +
    path_prefix.trim_end(chars="/").to_string()
  { path_prefix, local_dir }
}

///|
/// Register a static directory for serving SSG output
/// This serves HTML files from .sol/prod/static/{path_prefix}
pub fn serve_static_dir(app : App, config : StaticDirServeConfig) -> Unit {
  let prefix = config.path_prefix.trim_end(chars="/").to_string()
  let local_dir = config.local_dir

  // Serve index.html for directory roots
  app.get(
    prefix,
    @mars.handler(async fn(c) {
      serve_static_html_async(c, local_dir, "index.html")
    }),
  )

  // Serve all paths under the prefix
  app.get(
    prefix + "/*",
    @mars.handler(async fn(c) {
      let path = c.path()
      let start_idx = prefix.length() + 1
      let rest = path[start_idx:].to_string().trim_end(chars="/").to_string()

      // Try exact path first, then as directory index
      if rest.is_empty() {
        serve_static_html_async(c, local_dir, "index.html")
      } else if rest.has_suffix(".html") {
        serve_static_html_async(c, local_dir, rest)
      } else if rest.has_suffix(".css") {
        serve_static_css_async(c, local_dir, rest)
      } else if rest.has_suffix(".js") {
        serve_static_js_async(c, local_dir, rest)
      } else {
        // Try as directory with index.html
        serve_static_html_async(c, local_dir, rest + "/index.html")
      }
    }),
  )
}

///|
fn serve_static_html_async(
  c : Ctx,
  local_dir : String,
  filename : String,
) -> Unit {
  let path = local_dir + "/" + filename
  match read_file_sync(path) {
    Some(content) => c.html(content)
    None => c.text("Not found: " + filename)
  }
}

///|
fn serve_static_css_async(
  c : Ctx,
  local_dir : String,
  filename : String,
) -> Unit {
  let path = local_dir + "/" + filename
  c.set_header("Content-Type", "text/css")
  match read_file_sync(path) {
    Some(content) => c.text(content)
    None => c.text("/* Not found: " + filename + " */")
  }
}

///|
fn serve_static_js_async(
  c : Ctx,
  local_dir : String,
  filename : String,
) -> Unit {
  let path = local_dir + "/" + filename
  c.set_header("Content-Type", "application/javascript")
  match read_file_sync(path) {
    Some(content) => c.text(content)
    None => c.text("// Not found: " + filename)
  }
}

///|
/// Register static file serving middleware
pub fn serve_static(app : App, config? : StaticFileConfig) -> Unit {
  let cfg = config.unwrap_or(StaticFileConfig::default())
  let prefix = cfg.path_prefix
  let mappings = cfg.mappings
  // In dev mode, disable caching to avoid stale JS/CSS issues
  let cache_ctl = if is_dev_mode() {
    "no-cache, no-store, must-revalidate"
  } else {
    cfg.cache_control
  }
  app.get(
    prefix + "/*",
    @mars.handler(async fn(c) {
      let path = c.path()
      let start_idx = prefix.length() + 1
      let filename = path[start_idx:].to_string() // Remove prefix + "/"

      // Check mappings
      for mapping in mappings {
        let (url_file, local_path) = mapping
        if filename == url_file {
          match read_file_sync(local_path) {
            Some(content) => {
              let content_type = if url_file.has_suffix(".js") {
                "application/javascript"
              } else if url_file.has_suffix(".css") {
                "text/css"
              } else {
                "text/plain"
              }
              c.set_header("Content-Type", content_type)
              c.set_header("Cache-Control", cache_ctl)
              c.set_header("X-Content-Type-Options", "nosniff")
              c.text(content)
              return
            }
            None => {
              c.set_header("Content-Type", "application/javascript")
              c.set_header("Cache-Control", cache_ctl)
              c.set_header("X-Content-Type-Options", "nosniff")
              c.text("// " + url_file + " not found")
              return
            }
          }
        }
      }

      // Fallback: try to read from local_dir/filename, then .sol/{dev,prod}/static/filename
      // Dev is checked first as it's more commonly used during development
      let local_path = cfg.local_dir + "/" + filename
      let sol_dev_path = ".sol/dev/static/" + filename
      let sol_prod_path = ".sol/prod/static/" + filename
      let content = match read_file_sync(local_path) {
        Some(c) => Some(c)
        None =>
          match read_file_sync(sol_dev_path) {
            Some(c) => Some(c)
            None => read_file_sync(sol_prod_path)
          }
      }
      match content {
        Some(content) => {
          let content_type = if filename.has_suffix(".js") {
            "application/javascript"
          } else if filename.has_suffix(".css") {
            "text/css"
          } else if filename.has_suffix(".html") {
            "text/html"
          } else {
            "text/plain"
          }
          c.set_header("Content-Type", content_type)
          c.set_header("Cache-Control", cache_ctl)
          c.set_header("X-Content-Type-Options", "nosniff")
          c.text(content)
        }
        None => {
          c.set_header("Content-Type", "text/plain")
          c.set_header("Cache-Control", cache_ctl)
          c.set_header("X-Content-Type-Options", "nosniff")
          c.text("Not found: " + filename)
        }
      }
    }),
  )
}
