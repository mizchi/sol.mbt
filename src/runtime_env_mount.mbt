// Runtime environment and mount helpers

///|
/// Check if running in dev mode (SOL_DEV env variable)
extern "js" fn is_dev_mode() -> Bool =
  #| () => process.env.SOL_DEV === "1"

///|
/// Check if running in adapter mode (SOL_ADAPTER env variable)
/// When true, server startup is delegated to the adapter wrapper (serve.js)
extern "js" fn is_adapter_mode() -> Bool =
  #| () => process.env.SOL_ADAPTER === "1"

///|
/// HMR client script for dev mode (reads HMR_PORT from environment)
pub fn get_hmr_script() -> String {
  let port = get_hmr_port()
  "<script>(function(){var ws=new WebSocket('ws://'+location.hostname+':\{port}');ws.onmessage=function(e){var m=JSON.parse(e.data);if(m.type==='update'){location.reload()}else if(m.type==='full-reload'){location.reload()}else if(m.type==='error'){console.error('[HMR]',m.message)}};ws.onclose=function(){console.log('[HMR] Disconnected, reconnecting...');setTimeout(function(){location.reload()},1000)}})()</script>"
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
  ffi_get_hmr_port()
}

///|
extern "js" fn ffi_get_hmr_port() -> Int =
  #| () => parseInt(process.env.HMR_PORT || String(parseInt(process.env.PORT || '7777', 10) + 100), 10)

///|
/// Set environment variable
pub fn set_env(key : String, value : String) -> Unit {
  ffi_set_env(key, value)
}

///|
extern "js" fn ffi_set_env(key : String, value : String) -> Unit =
  #| (key, value) => { process.env[key] = value }
