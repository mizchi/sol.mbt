# Benchmarking Specification

`sol` のベンチ計測手順と `SOL_BENCH_MODE` の挙動は、このドキュメントを単一ソースとして扱います。

## 1. Scope

- 対象: `examples/sol_app` の HTTP レスポンス計測
- ツール: `k6`
- 主要スクリプト:
  - `bench/k6/sol-app-mix.js`
  - `bench/k6/sol-app-route-profile.js`

## 2. Standard Commands

リポジトリルートで実行:

```bash
# mix profile (single run)
just bench-k6

# mix profile (multi-run, median summary)
just bench-k6 60 30s 0.05 3

# route profile
just bench-k6-profile 10 10s

# compare two JSON results
just bench-k6-compare bench/k6/results/base.json bench/k6/results/candidate.json auto
```

## 3. SOL_BENCH_MODE Behavior

`just bench-k6` は `SOL_BENCH_MODE=1` で `examples/sol_app` サーバーを起動します。

このモードではベンチノイズ削減のため、以下の振る舞いに固定します。

- logger middleware を無効化
- k6 はベンチ専用 API を使用
  - `/api/bench/ping`
  - `/api/bench/test/[...path]`

本番挙動の検証ではなく、ルーティング/レンダリング性能の相対比較が目的です。

## 4. Multi-Run and Median

- `just bench-k6 <vus> <duration> <think_time> <runs>`
- `runs > 1` の場合:
  - 各 run の JSON を保存
  - `bench/k6/summarize-results.js` で median/min/max を集計

出力ファイル:

- `runs=1`: `RESULTS_JSON`（未指定時は `bench/k6/results/latest.json`）
- `runs>1`: `RESULTS_JSON_BASE`（未指定時は `bench/k6/results/latest`）を使い `*_runN.json` を生成

## 5. Result Comparison

`just bench-k6-compare <baseline> <candidate> [mode]`

- `mode=mix`: 全体指標（`p95/avg/error/rate`）を比較
- `mode=route`: route profile 指標（`page_*_duration`, `api_*_duration`）を比較
- `mode=auto`:
  - mix 指標 + route 指標を同時に比較

出力は `baseline` / `candidate` / `delta` / `delta%` / `verdict` の表形式です。
