// Router HMR support

///|
/// Check if running in dev mode (SOL_DEV env variable)
extern "js" fn is_dev_mode() -> Bool =
  #| () => process.env.SOL_DEV === "1"

///|
/// Get HMR port from environment (PORT + 100)
fn get_hmr_port() -> Int {
  ffi_get_hmr_port()
}

///|
extern "js" fn ffi_get_hmr_port() -> Int =
  #| () => parseInt(process.env.HMR_PORT || String(parseInt(process.env.PORT || '7777', 10) + 100), 10)

///|
/// HMR client script for dev mode (auto-reconnect on disconnect)
fn get_hmr_script() -> String {
  let port = get_hmr_port()
  "<script>(function(){var ws=new WebSocket('ws://'+location.hostname+':\{port}');ws.onmessage=function(e){var m=JSON.parse(e.data);if(m.type==='update'||m.type==='full-reload'){location.reload()}else if(m.type==='error'){console.error('[HMR]',m.message)}};ws.onclose=function(){setTimeout(function(){location.reload()},1000)}})()</script>"
}
