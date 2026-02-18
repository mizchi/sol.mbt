// Runtime bootstrap entrypoints

///|
priv enum RuntimeBootstrapMode {
  AdapterExportOnly
  InitFsAndMaybeServe
}

///|
fn select_bootstrap_mode(
  is_adapter~ : Bool,
  is_node~ : Bool,
) -> RuntimeBootstrapMode {
  if is_adapter && not(is_node) {
    RuntimeBootstrapMode::AdapterExportOnly
  } else {
    RuntimeBootstrapMode::InitFsAndMaybeServe
  }
}

///|
fn with_created_app(callback : (App) -> Unit) -> Unit {
  // Initialize fs module first, then create Server app
  with_initialized_fs(fn() {
    let app = @mars.Server::new()
    callback(app)
  })
}

///|
/// Create a new Sol application and run callback with it
/// This is useful for main function that cannot be async
#deprecated
pub fn create_app_then(callback : (App) -> Unit) -> Unit {
  with_created_app(callback)
}

///|
/// Run a Sol application with standard configuration
/// This is the recommended way to start a Sol server.
///
/// Example:
/// ```moonbit nocheck
/// fn main {
///   @sol.run(fn(app) { @sol.page(app, "/", home_page) |> @sol.serve_static() })
/// }
/// ```
pub fn run(configure : (App) -> Unit, port? : Int) -> Unit {
  let port = port.unwrap_or_else(get_port)
  with_created_app(fn(app) {
    configure(app)
    export_runtime_app(app)
    maybe_start_server(app, port)
  })
}

///|
/// Run a Sol application that creates its own app instance
/// This is used for generated configure_app() functions that take no parameters.
///
/// Example:
/// ```moonbit nocheck
/// fn main {
///   @sol.run_app(configure_app)
/// }
/// ```
pub fn run_app(create_and_configure : () -> App, port? : Int) -> Unit {
  let port = port.unwrap_or_else(get_port)
  let mode = select_bootstrap_mode(
    is_adapter=is_adapter_mode(),
    is_node=runtime_is_node(),
  )
  match mode {
    RuntimeBootstrapMode::AdapterExportOnly => {
      let app = create_and_configure()
      export_runtime_app(app)
    }
    RuntimeBootstrapMode::InitFsAndMaybeServe =>
      with_initialized_fs(fn() {
        let app = create_and_configure()
        export_runtime_app(app)
        maybe_start_server(app, port)
      })
  }
}
