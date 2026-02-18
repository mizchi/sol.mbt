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
