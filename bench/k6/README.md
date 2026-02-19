# k6 Benchmarks

`k6` で `examples/sol_app` の主要ルートを負荷計測するためのスクリプトです。

仕様の単一ソース: `docs/benchmarking.md`

## 前提

```bash
brew install k6
```

## 使い方

リポジトリルートで実行:

```bash
# デフォルト: 20 VUs / 30s
just bench-k6

# クイック確認: 5 VUs / 10s
just bench-k6-quick

# 60 VUs / 30s / think 0.05 を 3 回実行して中央値を確認
just bench-k6 60 30s 0.05 3

# 2つの結果 JSON を差分比較（mix + route）
just bench-k6-compare bench/k6/results/base.json bench/k6/results/candidate.json auto
```

## 単体実行

サーバーを別ターミナルで起動している場合は直接 `k6` でも実行できます。

```bash
BASE_URL=http://localhost:7777 k6 run bench/k6/sol-app-mix.js
```

ルート別にボトルネックを確認する場合:

```bash
BASE_URL=http://localhost:7777 VUS=10 DURATION=10s k6 run bench/k6/sol-app-route-profile.js
```

`examples/sol_app` では `SOL_BENCH_MODE=1` を付けてサーバーを起動すると、
logger ミドルウェアを無効化して純粋なレスポンス性能を測れます。

k6 スクリプトはデバッグ API ではなくベンチ専用 API を使います。

- `/api/bench/ping`
- `/api/bench/test/[...path]`

`just bench-k6` は `runs > 1` を指定すると、各 run の JSON を保存し、
最後に `bench/k6/summarize-results.js` で中央値を集計します。

`just bench-k6-compare` は 2 つの JSON を比較し、`p95/avg/error/rate` の差分表を表示します。
`mode` は `mix` / `route` / `auto` から選べます。

### パラメータ

- `BASE_URL` (default: `http://localhost:7777`)
- `VUS` (default: `20`)
- `DURATION` (default: `30s`)
- `THINK_TIME` (default: `0.1`)
- `runs` (`just bench-k6` 第4引数, default: `1`)
- `RESULTS_JSON` (optional, `runs=1` のときのみ有効)
- `RESULTS_JSON_BASE` (optional, `runs>1` のときの出力先プレフィックス。例: `bench/k6/results/high_load`)
- `mode` (`just bench-k6-compare` 第3引数, default: `auto`)
