// Sol - SSR-first Web Framework for MoonBit
//
// Built on top of Mars, providing SSR with Luna VNodes.
// Inspired by Next.js, Solid Start, and Qwik City.
//

///|
/// Mars app type alias
pub type App = @mars.Server

///|
/// Mars context type alias
pub type Ctx = @mars.Context

///|
/// Render a VNode to HTML string with full document wrapper
/// Use hydration=true to enable hydration markers (for pages with Islands)
pub fn[E] render_page(
  node : @luna.Node[E, String],
  title? : String,
  head? : String,
  hydration? : Bool,
) -> String {
  let title_str = title.unwrap_or("App")
  let head_str = head.unwrap_or("")
  let enable_hydration = hydration.unwrap_or(false)
  let body_html = if enable_hydration {
    @render.render_to_string_with_hydration(node)
  } else {
    @render.render_to_string(node).html
  }
  "<!DOCTYPE html><html><head><meta charset=\"UTF-8\"><meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\"><title>" +
  title_str +
  "</title>" +
  head_str +
  "</head><body><div id=\"app\">" +
  body_html +
  "</div></body></html>"
}

///|
/// Render a VNode to HTML string without document wrapper (for partial/fragment responses)
pub fn[E] render_fragment(node : @luna.Node[E, String]) -> String {
  @render.render_to_string_with_hydration(node)
}

///|
/// Register a page route that renders a VNode
/// Use hydration=true for pages with Islands (adds loader script and hydration markers)
pub fn[E] page(
  app : App,
  path : String,
  render_fn : (Ctx) -> @luna.Node[E, String],
  title? : String,
  head? : String,
  hydration? : Bool,
  loader_url? : String,
) -> Unit {
  app.get(
    path,
    @mars.handler(async fn(c) {
      let node = render_fn(c)
      let enable_hydration = hydration.unwrap_or(false)
      // Add HMR script in dev mode
      let dev_script = if is_dev_mode() { get_hmr_script() } else { "" }
      if enable_hydration {
        // Hydration enabled: render with hydration markers and include loader script
        let loader = loader_url.unwrap_or(default_loader_url)
        let loader_script = "<script type=\"module\" src=\"" +
          loader +
          "\"></script>"
        let full_head = head.unwrap_or("") + loader_script + dev_script
        let html = render_page(node, title?, head=full_head, hydration=true)
        c.html(html)
      } else {
        // Static page: render without hydration (but still add HMR in dev)
        let full_head = head.unwrap_or("") + dev_script
        let html = render_page(node, title?, head=full_head)
        c.html(html)
      }
    }),
  )
}

/// Create a plain JavaScript object from key-value pairs
/// Use this for API responses instead of MoonBit Map
extern "js" fn ffi_create_json_obj(pairs : Array[(String, @js.Any)]) -> @js.Any =
  #| (pairs) => Object.fromEntries(pairs.map(p => [p._0, p._1]))

///|
/// Create a JSON object for API responses
pub fn json_obj(pairs : Array[(String, @js.Any)]) -> @js.Any {
  ffi_create_json_obj(pairs)
}

///|
/// FFI to convert MoonBit Json to JavaScript value
extern "js" fn ffi_json_to_any(json : Json) -> @js.Any =
  #| (json) => {
  #|   // Handle MoonBit Json tagged union
  #|   if (json === null || json === undefined) return null;
  #|   switch (json.$tag) {
  #|     case 0: return null;                    // Null
  #|     case 1: return json._0;                 // True -> true
  #|     case 2: return json._0;                 // False -> false
  #|     case 3: return json._0;                 // Number
  #|     case 4: return json._0;                 // String
  #|     case 5: return json._0.map(j => arguments.callee(j)); // Array
  #|     case 6: {                               // Object
  #|       const result = {};
  #|       for (const [k, v] of json._0.entries()) {
  #|         result[k] = arguments.callee(v);
  #|       }
  #|       return result;
  #|     }
  #|     default: return json;
  #|   }
  #| }

///|
/// Convert MoonBit Json to JavaScript Any value
pub fn json_to_any(json : Json) -> @js.Any {
  ffi_json_to_any(json)
}

///|
/// Convert MoonBit Json array to JavaScript Any value
pub fn json_array_to_any(arr : Array[Json]) -> @js.Any {
  // Map each Json to Any and return as JS array
  let result : Array[@js.Any] = arr.map(fn(j) { ffi_json_to_any(j) })
  ffi_array_to_any(result)
}

///|
extern "js" fn ffi_array_to_any(arr : Array[@js.Any]) -> @js.Any =
  #| (arr) => arr

// ============================================================================
// Island Architecture Support
// ============================================================================

///|
/// Default loader script URL
pub let default_loader_url : String = "/loader.js"

///|
/// Island configuration
pub struct IslandConfig[E] {
  /// Unique identifier for the island
  id : String
  /// ES module URL for hydration script
  script_url : String
  /// Hydration trigger type
  trigger : @luna.TriggerType
  /// State configuration
  state : @stella.StateConfig
  /// SSR rendered content (VNode)
  content : @luna.Node[E, String]?
  /// SSR rendered HTML string (alternative to content)
  ssr_html : String?
}

///|
/// Create a new island configuration
pub fn[E] IslandConfig::new(
  id : String,
  script_url : String,
) -> IslandConfig[E] {
  {
    id,
    script_url,
    trigger: @luna.TriggerType::Load,
    state: @stella.StateConfig::Empty,
    content: None,
    ssr_html: None,
  }
}

///|
/// Builder: set trigger type
pub fn[E] IslandConfig::with_trigger(
  self : IslandConfig[E],
  trigger : @luna.TriggerType,
) -> IslandConfig[E] {
  { ..self, trigger, }
}

///|
/// Builder: set inline state from JSON
pub fn[E] IslandConfig::with_state(
  self : IslandConfig[E],
  json : String,
) -> IslandConfig[E] {
  { ..self, state: @stella.StateConfig::Inline(json) }
}

///|
/// Builder: set state from script reference
pub fn[E] IslandConfig::with_state_ref(
  self : IslandConfig[E],
  script_id : String,
) -> IslandConfig[E] {
  { ..self, state: @stella.StateConfig::ScriptRef(script_id) }
}

///|
/// Builder: set state from URL
pub fn[E] IslandConfig::with_state_url(
  self : IslandConfig[E],
  url : String,
) -> IslandConfig[E] {
  { ..self, state: @stella.StateConfig::Url(url) }
}

///|
/// Builder: set SSR content from VNode
pub fn[E] IslandConfig::with_content(
  self : IslandConfig[E],
  node : @luna.Node[E, String],
) -> IslandConfig[E] {
  { ..self, content: Some(node) }
}

///|
/// Builder: set SSR content from raw HTML string
pub fn[E] IslandConfig::with_ssr_html(
  self : IslandConfig[E],
  html : String,
) -> IslandConfig[E] {
  { ..self, ssr_html: Some(html) }
}

///|
/// Render an island to HTML string
pub fn[E] render_island(config : IslandConfig[E]) -> String {
  // Priority: ssr_html > content (VNode) > empty
  let ssr_content = match config.ssr_html {
    Some(html) => html
    None =>
      match config.content {
        Some(node) => @render.render_to_string_with_hydration(node)
        None => ""
      }
  }

  // Convert state to shard format
  let shard_config = @stella.ShardConfig::new(config.id, config.script_url)
    .with_trigger(config.trigger)
    .with_ssr_content(ssr_content)

  // Apply state configuration
  let final_config = match config.state {
    @stella.StateConfig::Empty => shard_config
    @stella.StateConfig::Inline(json) => shard_config.with_state(json)
    @stella.StateConfig::ScriptRef(id) => shard_config.with_state_ref(id)
    @stella.StateConfig::Url(url) => shard_config.with_state_url(url)
  }
  @stella.generate_shard(final_config).html
}

///|
/// Render a page with islands
/// Includes the loader script automatically
pub fn render_island_page(
  islands : Array[String],
  title? : String,
  head? : String,
  loader_url? : String,
) -> String {
  let title_str = title.unwrap_or("App")
  let head_str = head.unwrap_or("")
  let loader = loader_url.unwrap_or(default_loader_url)
  let sb = StringBuilder::new(size_hint=4096)
  sb.write_string(
    "<!DOCTYPE html><html><head><meta charset=\"UTF-8\"><meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\"><title>",
  )
  sb.write_string(title_str)
  sb.write_string("</title>")
  sb.write_string(head_str)
  sb.write_string("<script type=\"module\" src=\"")
  sb.write_string(loader)
  sb.write_string("\"></script></head><body>")
  for island_html in islands {
    sb.write_string(island_html)
  }
  sb.write_string("</body></html>")
  sb.to_string()
}

///|
/// Register an island page route
pub fn[E] island_page(
  app : App,
  path : String,
  render_fn : (Ctx) -> Array[IslandConfig[E]],
  title? : String,
  head? : String,
  loader_url? : String,
) -> Unit {
  app.get(
    path,
    @mars.handler(async fn(c) {
      let islands = render_fn(c)
      let island_htmls = islands.map(fn(config) { render_island(config) })
      let html = render_island_page(island_htmls, title?, head?, loader_url?)
      c.html(html)
    }),
  )
}

///|
/// Render island with separate state script (for large state)
pub fn[E] render_island_with_state_script(
  config : IslandConfig[E],
  state_json : String,
) -> String {
  // Priority: ssr_html > content (VNode) > empty
  let ssr_content = match config.ssr_html {
    Some(html) => html
    None =>
      match config.content {
        Some(node) => @render.render_to_string_with_hydration(node)
        None => ""
      }
  }
  let shard_config = @stella.ShardConfig::new(config.id, config.script_url)
    .with_trigger(config.trigger)
    .with_ssr_content(ssr_content)
  @stella.generate_shard_with_state_script(shard_config, state_json).html
}

///|
/// Generate state script tag for external state
pub fn generate_state_script(id : String, json : String) -> String {
  @stella.generate_state_script(id, json)
}

// ============================================================================
// Island VNode Support (using @luna.island)
// ============================================================================

///|
/// Create an Island VNode from a component render function
/// This is the recommended way to create Islands with type-safe VNode children
pub fn[E] island(
  id : String,
  url : String,
  state : String,
  children : Array[@luna.Node[E, String]],
  trigger? : @luna.TriggerType = @luna.TriggerType::Load,
) -> @luna.Node[E, String] {
  @luna.island(id, url, state, children, trigger~)
}

///|
/// Create an Island VNode with a render function for children
pub fn[E] island_with(
  id : String,
  url : String,
  state : String,
  render : () -> @luna.Node[E, String],
  trigger? : @luna.TriggerType = @luna.TriggerType::Load,
) -> @luna.Node[E, String] {
  @luna.island(id, url, state, [render()], trigger~)
}

///|
/// Render a VNode to HTML string
/// Use hydration=true to enable hydration markers
pub fn[E] render_node(
  node : @luna.Node[E, String],
  hydration? : Bool = false,
) -> String {
  if hydration {
    @render.render_to_string_with_hydration(node)
  } else {
    @render.render_to_string(node).html
  }
}

// ============================================================================
// Web Components Island VNode Support (using @luna.wc_island)
// ============================================================================

///|
/// Default wc-loader script URL
pub let default_wc_loader_url : String = "/static/wc-loader.js"

///|
/// Create a Web Components Island VNode
/// Uses Declarative Shadow DOM for SSR and wc-loader for hydration
pub fn[E] wc_island(
  name : String,
  url : String,
  styles : String,
  state : String,
  children : Array[@luna.Node[E, String]],
  trigger? : @luna.TriggerType = @luna.TriggerType::Load,
) -> @luna.Node[E, String] {
  @luna.wc_island(name, url, styles, state, children, trigger~)
}

///|
/// Create a Web Components Island VNode with a render function for children
pub fn[E] wc_island_with(
  name : String,
  url : String,
  styles : String,
  state : String,
  render : () -> @luna.Node[E, String],
  trigger? : @luna.TriggerType = @luna.TriggerType::Load,
) -> @luna.Node[E, String] {
  @luna.wc_island(name, url, styles, state, [render()], trigger~)
}

///|
/// Register a page route with Web Components islands
/// Uses wc-loader for hydration
pub fn[E] wc_page(
  app : App,
  path : String,
  render_fn : (Ctx) -> @luna.Node[E, String],
  title? : String,
  head? : String,
  wc_loader_url? : String,
) -> Unit {
  app.get(
    path,
    @mars.handler(async fn(c) {
      let node = render_fn(c)
      let loader = wc_loader_url.unwrap_or(default_wc_loader_url)
      let loader_script = "<script type=\"module\" src=\"" +
        loader +
        "\"></script>"
      // Add HMR script in dev mode
      let dev_script = if is_dev_mode() { get_hmr_script() } else { "" }
      let full_head = head.unwrap_or("") + loader_script + dev_script
      let html = render_page(node, title?, head=full_head, hydration=true)
      c.html(html)
    }),
  )
}

// ============================================================================
// Streaming SSR Support
// ============================================================================

///|
/// Render a page with streaming SSR and async boundaries (VAsync nodes)
/// Returns a ReadableStream for HTTP response
/// VAsync nodes in the tree will be rendered with fallback first,
/// then resolved content will be streamed as replacement scripts
pub fn render_streaming_page(
  shell : @luna.Node[Unit, String],
  title? : String,
  head? : String,
  loader_url? : String,
) -> @http.Response {
  let title_str = title.unwrap_or("App")
  let head_str = head.unwrap_or("")
  let loader = loader_url.unwrap_or(default_loader_url)

  // Build header HTML
  let header_html = "<!DOCTYPE html><html><head><meta charset=\"UTF-8\"><meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\"><title>" +
    title_str +
    "</title>" +
    head_str +
    "<script type=\"module\" src=\"" +
    loader +
    "\"></script></head><body><div id=\"app\">"

  // Build footer HTML
  let footer_html = "</div></body></html>"

  // Create streaming response with async resolution
  let stream = create_streaming_response_with_async(
    header_html, footer_html, shell,
  )
  ffi_create_stream_response(stream)
}

///|
/// Create a ReadableStream that streams HTML with async resolution
fn create_streaming_response_with_async(
  header : String,
  footer : String,
  shell : @luna.Node[Unit, String],
) -> @js.Any {
  ffi_create_streaming_response_async(header, footer, async fn(write) {
    // Use render_to_stream_with_async which handles VAsync nodes
    @stream_renderer.render_to_stream_with_async(
      shell,
      @stream_renderer.StreamWriter::from_callback(write),
    )
  })
}

///|
extern "js" fn ffi_create_streaming_response_async(
  header : String,
  footer : String,
  render_with_async : async ((String) -> Unit) -> Unit,
) -> @js.Any =
  #| (header, footer, renderWithAsync) => new ReadableStream({
  #|   async start(controller) {
  #|     const encoder = new TextEncoder();
  #|     const write = (chunk) => controller.enqueue(encoder.encode(chunk));
  #|     write(header);
  #|     await renderWithAsync(write);
  #|     write(footer);
  #|     controller.close();
  #|   }
  #| })

///|
extern "js" fn ffi_create_stream_response(stream : @js.Any) -> @http.Response =
  #| (stream) => new Response(stream, { headers: { 'Content-Type': 'text/html; charset=utf-8' } })

///|
/// Register a streaming page route with async support
/// VAsync nodes in the rendered tree will be handled automatically
/// Note: This uses ReadableStream internally for proper streaming support
pub fn streaming_page(
  app : App,
  path : String,
  render_fn : (Ctx) -> @luna.Node[Unit, String],
  title? : String,
  head? : String,
  loader_url? : String,
) -> Unit {
  app.get(
    path,
    @mars.handler(async fn(c) {
      let shell = render_fn(c)
      let title_str = title.unwrap_or("App")
      let head_str = head.unwrap_or("")
      let loader = loader_url.unwrap_or(default_loader_url)
      let header_html = "<!DOCTYPE html><html><head><meta charset=\"UTF-8\"><meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\"><title>" +
        title_str +
        "</title>" +
        head_str +
        "<script type=\"module\" src=\"" +
        loader +
        "\"></script></head><body><div id=\"app\">"
      let footer_html = "</div></body></html>"
      // Create streaming response and send via FFI
      let stream = create_streaming_response_with_async(
        header_html, footer_html, shell,
      )
      ffi_set_streaming_response(c, stream)
    }),
  )
}

///|
/// Set streaming response via FFI (for Mars Context)
extern "js" fn ffi_set_streaming_response(ctx : Ctx, stream : @js.Any) -> Unit =
  #| (ctx, stream) => {
  #|   const response = new Response(stream, { headers: { 'Content-Type': 'text/html; charset=utf-8' } });
  #|   ctx.platform.response_resolve(response);
  #| }

///|
/// Render a VNode to HTML with preload URLs for islands
/// Returns SSRResult with html and preload_urls
pub fn[E] render_with_island_preloads(
  node : @luna.Node[E, String],
) -> @render.SSRResult {
  @render.render_to_string(node, preload=true)
}

///|
/// Render a page with automatic modulepreload tags for islands
pub fn[E] render_page_with_preloads(
  node : @luna.Node[E, String],
  title? : String,
  head? : String,
  hydration? : Bool,
) -> String {
  let title_str = title.unwrap_or("App")
  let enable_hydration = hydration.unwrap_or(false)

  // Render and collect preload URLs
  let _ = enable_hydration // Reserved for future use
  let result = @render.render_to_string(node, preload=true)

  // Generate preload tags
  let preload_tags = @render.generate_preload_tags(result.preload_urls)

  // Combine head with preload tags
  let head_str = head.unwrap_or("") + preload_tags
  "<!DOCTYPE html><html><head><meta charset=\"UTF-8\"><meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\"><title>" +
  title_str +
  "</title>" +
  head_str +
  "</head><body><div id=\"app\">" +
  result.html +
  "</div></body></html>"
}

// ============================================================================
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
