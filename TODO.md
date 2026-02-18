# mars thin wrapper 向けリファクタ TODO

## 方針

- `sol` は `mars` の薄いラッパーに寄せる
- `sol` の責務は「file based routing の割り当て」「SSR」「アセットローダー」に限定する
- `mbtx` / `wasip2` / `wagi` 前提の `.wasm` マウント統合は `mars` との境界を明確にして実装する

## 進捗

- [x] `moon clean` 実施
- [x] ベースライン確認（`moon test --target js src/router`, `moon test --target js src/action`）
- [x] `router` を責務分割（`router_config` / `route_params` / `route_registration` / `route_rendering` / `router_hmr`）
- [x] `register_routes` / `register_server_routes` の config 解決を `resolve_router_config` に統一
- [x] `runtime` を起動境界で分割（`runtime_bootstrap` / `runtime_app_export` / `runtime_env_mount`）
- [x] `runtime` の SSR/Island/Streaming/Static Serving をファイル分割（`runtime` / `runtime_island` / `runtime_streaming` / `runtime_static_serving`）
- [x] `sol` / `mars` で共有しやすい Hot Reload API を `hot_reload` パッケージへ分離（port 解決・script 注入・HTML 注入）
- [x] `sol_routes` の API method 登録を `handle_compiled_api_route` + 共通登録ヘルパに統一
- [x] `routes/file_router.mbt` の catch-all 動的パラメータ処理を実装（値正規化/空値対応）
- [x] `Layout` の扱いを仕様化（`register_routes` は path grouping のみ、合成は `sol_routes`）
- [x] catch-all パラメータの URL エンコード/デコード規約を仕様化（`%2F` を含むケース）
- [x] `register_routes` と `register_sol_routes` の使い分けを README に反映

## 優先タスク

- [x] [P1] `Context` の params 抽出を `mars` 公開 API 経由に統一する  
  対応: `extract_route_params` を `Context::param` ベースに変更し、`c.params?.data` 依存を削除

- [x] [P2] JSON レスポンス送信を共通ファサードに寄せる（`router`/`action` 重複削減）  
  対応: `src/internal/mars_response/mars_response.mbt` を追加し、`router`/`action` から利用

- [x] [P2] ルート登録の重複削減  
  対応: `register_routes_inner` / `register_server_routes_inner` を廃止し、`register_route_tree` + 共通 API 登録ヘルパへ統合

- [x] [P2] `runtime` の起動責務を `mars` adapter 前提へ再編成する  
  対応: `export_runtime_app` / `maybe_start_server` / `with_initialized_fs` へ起動境界を集約

- [x] [P3] wasm hint/manifest の責務整理  
  対応: `generate_mars_adapter_hints` を追加し、`mars` adapter の `manifest_hint` / `binding_hint` を利用して `.sol/wasm/mars-adapter.hints` を出力

- [x] [P2] middleware 実行を `mars.compose` ベースへ統一  
  対応: `middleware.pipeline` を `@mars.compose` ベースへ変更し、`action` / `sol_routes` の独自 middleware ループを削除

## 次の概念整理候補

- [x] [P1] `runtime` の `mars` 重複 API を縮小（`create_app` / `api` / `api_post` / `get_request_path`）  
  対応: `src/runtime.mbt` から重複 API を削除し、CLI 生成コード/E2E 参照を `@mars.Server::new` と `app.get/post` へ移行
- [x] [P2] `source_path` 動的パラメータ形式を `k=v&...` 前提で複数パラメータ対応するか検討  
  対応: `file_router` の `source_path` 生成を主パラメータ + 追加パラメータの `k=v&...` 形式に拡張し、`page_generator` 側の複数クエリ復元テストを追加
- [x] [P3] `docs/` と README のルーティング仕様記述を一本化（重複削減）  
  対応: `docs/routing.md` を単一ソースとして追加し、`README` と既存ルーティング文書を参照ベースに統合
- [x] [P2] middleware 実行時の 500 エラーハンドリングを共通化  
  対応: `@middleware.run_or_500` を追加し、`action` / `sol_routes` のローカル実装を削除して統一
- [x] [P2] 500 JSON エラーレスポンス送信を共通ヘルパへ統一  
  対応: `@mars_response.send_internal_error` を追加し、`action` / `sol_routes` の 500 応答分岐を統一
- [x] [P3] `middleware.to_handler` を段階的縮小（deprecated 化）  
  対応: `to_handler` を `#deprecated` 指定し、公開 API 縮小の移行フェーズを開始

## 追加で潰した項目（2026-02-18）

- [x] [P2] SSR page shell テンプレ処理の重複削減  
  対応: `src/internal/page_shell` を追加し、`runtime` / `router` の document/template 組み立てを統一
- [x] [P2] JavaScript object 生成の重複削減  
  対応: `src/internal/js_any` を追加し、`runtime` / `router` の `json_obj` 実装を統一
- [x] [P2] `router` 側 HMR 中継層の削除  
  対応: `src/router/router_hmr.mbt` を廃止し、`@hot_reload.with_dev_head_script` へ統一
- [x] [P3] HMR メッセージ型の導入と timestamp overflow 修正  
  対応: `HmrMessage` を追加し、`notify_update` の timestamp を `Double` で送信
- [x] [P3] `just sol` の CLI エントリパス不整合を修正  
  対応: `justfile` の参照先を `target/js/debug/build/cli/cli.js` に統一
- [x] [P3] deprecated warning の解消  
  対応: `create_app_then` / `serve` の内部実装を分離し、内部呼び出しから deprecated シンボルを除去
- [x] [P3] static css/js 配信ロジックの重複削減  
  対応: `serve_static_text_file` へ統合

## 次の候補（未着手）

- [ ] [P2] `runtime_env_mount` の `get_hmr_script` / `get_hmr_port` を deprecated 化し `@hot_reload` 直接利用へ寄せる
- [ ] [P2] `runtime_static_serving` の `text_response` / `js_response` / `static_response` の使用実態を確認し、不要公開 API を縮小する
