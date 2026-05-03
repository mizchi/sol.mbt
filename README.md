# mizchi/sol — moved

This repository has been retired. Sol now lives in the
[**luna.mbt monorepo**](https://github.com/mizchi/luna.mbt) alongside its
sibling packages:

| Package | Role | Path in monorepo |
|---------|------|------------------|
| [`mizchi/luna`](https://mooncakes.io/docs/mizchi/luna/)   | UI primitive — VDOM, hydration, stream renderer, Island runtime | `src/`    |
| [`mizchi/sol`](https://mooncakes.io/docs/mizchi/sol/)     | Mars-based SSR framework with file-based routing                | `sol/`    |
| [`mizchi/astra`](https://mooncakes.io/docs/mizchi/astra/) | Mountable Mars middleware for static site generation            | `astra/`  |

## Why the move

Static site generation (`sol --mode ssg`, `sol new --doc`) was extracted
into the dedicated [`mizchi/astra`](https://github.com/mizchi/luna.mbt/tree/main/astra)
package in `sol@0.16.0`. The three packages now share one workspace,
release together, and have clean unidirectional dep edges.

## Migration

If you were on `sol@0.15.x` with SSG features:

```diff
  // moon.mod.json
  {
    "deps": {
-     "mizchi/sol": "0.15.3"
+     "mizchi/sol": "0.16.0",
+     "mizchi/astra": "0.1.0"
    }
  }
```

```diff
- sol build --mode ssg
+ astra build

- sol dev --mode ssg
+ astra dev
```

See `astra/CHANGELOG.md` and `sol/CHANGELOG.md` in the new monorepo for
the full migration notes.

## Issues / PRs

Please open new issues at
**https://github.com/mizchi/luna.mbt/issues** with the relevant package
label (`luna`, `sol`, or `astra`). This repo is archived and read-only.

## License

MIT (unchanged).
