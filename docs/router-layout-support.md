# Router Layout Support Matrix

`sol` では、`mars` ラッパーとして責務を分離するために Layout の扱いを2系統に分けています。

## 1. `@luna/core/routes` (`register_routes` / `register_server_routes`)

- `Layout(segment, children, layout)` の `layout` は **このアダプタでは適用しない**。
- この経路では `Layout` は **パスのグルーピング（prefix 付与）** としてだけ扱う。

理由:
- 文字列 ID ベースの薄いルーティング割当層として維持するため。
- 実際のレイアウト合成ロジックを `sol_routes` 側に集約するため。

## 2. `sol_routes` (`register_sol_routes`)

- `SolRoutes::Layout` は `ServerNode` レベルでレイアウト関数を適用する。
- ルートの内側から外側へレイアウトを合成し、fragment/full page の両方に対応する。

## 運用ルール

- 「Layout を実際に合成したい」場合は `sol_routes` を使う。
- 「file based routing 割当だけ行う」場合は `register_routes` 系を使う。
