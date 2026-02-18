# Catch-all Parameter Encoding Rule

`file_router` で生成する動的ページの `source_path` クエリは、以下の規約で扱います。

## 目的

- `catch-all` 値に `/` を含む場合でも、`source_path` を安全に直列化する
- `=` や `&` を含む値でも壊れないようにする

## 規約

- `source_path` に埋め込むパラメータ値は **URL エンコード**する
  - 例: `guide/intro` → `guide%2Fintro`
- SSG 生成時 (`page_generator`) はクエリ値を **URL デコード**して扱う
  - 例: `guide%2Fintro` → `guide/intro`

## 例

- 入力: `slug = "guide/intro"`
- `source_path`: `docs/_...slug_/index.md?slug=guide%2Fintro`
- 生成時の params: `{ "slug": "guide/intro" }`

## 注意

- `register_routes` / `register_sol_routes` の実行時ルーティングパラメータ（`Context::param`）にはこの規約は不要。
- この規約は **SSG 用の `source_path` 内部表現** に限定される。
