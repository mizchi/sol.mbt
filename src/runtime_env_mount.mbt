// Runtime environment and mount helpers

/// Check if running in adapter mode (SOL_ADAPTER env variable)
/// When true, server startup is delegated to the adapter wrapper (serve.js)
extern "js" fn is_adapter_mode() -> Bool =
  #| () => process.env.SOL_ADAPTER === "1"

///|
/// HMR client script for dev mode (reads HMR_PORT from environment)
pub fn get_hmr_script() -> String {
  @hot_reload.client_script_from_env()
}

///|
extern "js" fn ffi_init_fs() -> @js.Promise[Unit] =
  #| () => import('node:fs').then(fs => { globalThis.__SOL_FS__ = fs; })

///|
fn with_initialized_fs(callback : () -> Unit) -> Unit {
  let _ = ffi_init_fs().then(fn(_) {
    callback()
    @js.Promise::resolve(@js.any(()))
  })
}

///|
/// Get port from PORT environment variable, default to 7777
pub fn get_port() -> Int {
  ffi_get_port()
}

///|
extern "js" fn ffi_get_port() -> Int =
  #| () => parseInt(process.env.PORT || '7777', 10)

///|
/// Get HMR port from HMR_PORT environment variable, default to PORT + 100
pub fn get_hmr_port() -> Int {
  @hot_reload.hmr_port_from_env()
}

///|
/// Set environment variable
pub fn set_env(key : String, value : String) -> Unit {
  ffi_set_env(key, value)
}

///|
extern "js" fn ffi_set_env(key : String, value : String) -> Unit =
  #| (key, value) => { process.env[key] = value }
