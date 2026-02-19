# k6 Benchmarks

`k6` で `examples/sol_app` の主要ルートを負荷計測するためのスクリプトです。

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
logger ミドルウェアを無効化し、デバッグ API（`/api/middleware-test`, `/api/test/[...path]`）の
レスポンスを最小化して純粋なレスポンス性能を測れます。

### パラメータ

- `BASE_URL` (default: `http://localhost:7777`)
- `VUS` (default: `20`)
- `DURATION` (default: `30s`)
- `THINK_TIME` (default: `0.1`)
- `RESULTS_JSON` (optional, 例: `bench/k6/results/latest.json`)
