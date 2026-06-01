# wcx — AGENTS.md

## Build & run

```sh
mix escript.build          # produces ./wc
./wc -lwL file.txt          # usage example
```

## Test

```sh
mix test                    # all tests
```

## CI pipeline (`.forgejo/workflows/ci.yaml`)

Order matters — each step must pass before the next:

1. `mix format --check-formatted`
2. `mix compile --warnings-as-errors`
3. `mix escript.build`
4. `mix test`

## Project layout

- `lib/wc.ex` — CLI entrypoint (`WC.main/1`), flag parsing, output formatting
- `lib/wc/counter.ex` — stream-based line/word/byte/char counting (`WC.Counter`)
- `test/wc_test.exs` — 26 tests covering counter, parse, and output
- `test/fixtures/` — fixture files for file-based tests

## Key facts

- Pure Elixir, zero dependencies
- Escript entrypoint: `WC.main/1` (config in `mix.exs`)
- Default flags (no args): `-lwc`
- File reading uses `File.stream!` (not `File.open` + `IO.stream` — the latter corrupts UTF-8)
