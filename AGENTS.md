# wcx — AGENTS.md

## Build & run

```sh
mix escript.build          # produces ./wc
./wc -lwL file.txt          # usage example
```

## Test

```sh
mix test                    # all tests
mix test --cover            # 90% coverage gate (Elixir default summary threshold)
```

## CI pipeline (`.forgejo/workflows/ci.yaml`)

Order matters — each step must pass before the next:

1. `mix format --check-formatted`
2. `mix compile --warnings-as-errors`
3. `mix escript.build`
4. `mix test`

## Code intelligence (Expert LSP)

- The Elixir language server is Expert, not `elixir-ls` (which is disabled in the opencode config)
- Prefer the `lsp` tool over `rg`/`Read` for symbol, definition, reference, and type questions: `documentSymbol`, `workspaceSymbol`, `goToDefinition`, `findReferences`, `hover`
- No call hierarchy: Expert does not advertise `callHierarchyProvider`, so `prepareCallHierarchy`, `incomingCalls`, and `outgoingCalls` always return nothing. Use `findReferences` for "who calls this" and `goToDefinition` for "what does this call"
- `findReferences` resolves private functions and finds `&function/arity` captures, but `goToDefinition` on a capture returns nothing
- Positions are 1-based and must land on the name: column 7 for `def`, column 8 for `defp`. A position on whitespace returns "No results found" rather than an error
- Diagnostics are pushed by the server — read them instead of running `mix compile` for error feedback
- Expert builds a project engine in the background on first use; a cold first call can take a few seconds, so retry once before assuming it failed
- Document-scoped requests (`hover`, `definition`) only work on open files, so read the file first if a call returns nothing
- Expert needs `elixir` and `erl` on `PATH` to compile the project under analysis
- Upgrade the server with `expert-upgrade` (checksum-verified; `--check` compares installed vs latest)

## Project layout

- `lib/wc.ex` — CLI entrypoint (`WC.main/1`), flag parsing, output formatting
- `lib/wc/counter.ex` — stream-based line/word/byte/character counting (`WC.Counter`)
- `test/wc_test.exs` — 36 tests covering counter, parse, output, binary input, and `WC.main/1`
- `test/fixtures/` — fixture files for file-based tests

## Key facts

- Pure Elixir, zero dependencies
- Escript entrypoint: `WC.main/1` (config in `mix.exs`)
- Default flags (no args): `-lwc`
- `WC.Counter` accepts arbitrary binary chunks and buffers partial lines across chunk boundaries
- CLI file input uses 64 KiB raw `File.stream!/3` chunks; `WC.main/1` uses `IO.binstream/2` for raw stdin
- Invalid UTF-8 is normalized with `String.replace_invalid/1` for character counts; invalid-binary words use C-style ASCII whitespace
- `WC.run/1` uses a text stream so ExUnit `capture_io` can provide stdin
- Directories are reported to stderr and skipped while remaining files continue
