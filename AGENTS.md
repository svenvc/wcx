# wcx — AGENTS.md

## Build & run

```sh
mix escript.build          # produces ./wc
./wc -lwL file.txt          # usage example
```

Standalone binaries, one per platform, land in `burrito_out/`:

```sh
MIX_ENV=prod mix release --overwrite                                  # all five targets
MIX_ENV=prod BURRITO_TARGET=linux_x86_64 mix release --overwrite      # one target
./test/smoke.sh ./burrito_out/wc_macos_arm64                          # check a built binary
```

Needs Zig **0.16.0** exactly (Burrito hard-fails on any other version), `xz`, and
`7zz`/`7z` for the Windows target only. Downloaded ERTS archives are cached in
`~/.cache/burrito_file_cache` (macOS: `~/Library/Caches/burrito_file_cache`).

## Test

```sh
mix test                    # all tests
mix test --cover            # 90% coverage gate (Elixir default summary threshold)
./test/smoke.sh <binary>    # black-box checks against a standalone binary
```

`WC.Application` and `WC.Release*` are excluded from the coverage summary in
`mix.exs`: they only do their work inside a standalone binary, which
`mix release` and `test/smoke.sh` cover.

## CI pipeline

Two jobs, in `.forgejo/workflows/ci.yaml` and `.github/workflows/ci.yaml`.

`test` — order matters, each step must pass before the next:

1. `mix format --check-formatted`
2. `mix compile --warnings-as-errors`
3. `mix escript.build`
4. `mix test`

`release` — installs xz, 7z and Zig 0.16.0, then `MIX_ENV=prod mix release
--overwrite` followed by `test/smoke.sh` on the Linux binary. The GitHub workflow
additionally uploads `burrito_out/` as an artifact and smoke tests the Windows
binary on `windows-2022`.

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
- Expert does not load `runtime: false` deps, so it reports `struct <Burrito…> is undefined` in `lib/wc/release/erts_resolver.ex`. That is a false positive: `mix compile --warnings-as-errors` resolves it fine
- Upgrade the server with `expert-upgrade` (checksum-verified; `--check` compares installed vs latest). It typically lives in `~/.local/bin`, which may not be on `PATH`, so invoke it by absolute path if a bare call fails

## Project layout

- `lib/wc.ex` — CLI entrypoint (`WC.main/1`), flag parsing, output formatting
- `lib/wc/counter.ex` — stream-based line/word/byte/character counting (`WC.Counter`)
- `lib/wc/application.ex` — `:wc` application callback, the Burrito release entry point
- `lib/wc/release.ex` — Burrito release step (`WC.Release.wrap/1`)
- `lib/wc/release/erts_resolver.ex` — pins the prebuilt ERTS version (`WC.Release.ERTSResolver`)
- `test/wc_test.exs` — 46 tests covering counter, parse, output, binary input, and `WC.main/1`
- `test/wc/application_test.exs`, `test/wc/release/erts_resolver_test.exs` — release plumbing
- `test/smoke.sh` — black-box checks for a standalone binary, takes the binary path
- `test/fixtures/` — fixture files for file-based tests

## Key facts

- Escript entrypoint: `WC.main/1` (config in `mix.exs`); standalone binaries go through `WC.Application.start/2`
- `burrito` is a `runtime: false` dep, so the release payload holds only OTP, Elixir and `wc`
- `application/0` has `mod: {WC.Application, []}` because Burrito requires it, and Elixir escripts start the app before calling `main/1` too. The `__BURRITO` env var, set by Burrito's launcher, is the only thing that separates the two paths
- The ERTS version is pinned in `lib/wc/release/erts_resolver.ex` via a registered Burrito ERTS resolver, not through `:custom_erts` — a custom ERTS source stops Burrito from fetching the musl runtime that Linux binaries need
- The pin has to be `X.Y`: the BEAM Machine publishes no patch-level ERTS tarballs, so a host OTP like 29.1.1 404s
- Default flags (no args): `-lwc`
- `WC.Counter` accepts arbitrary binary chunks and buffers partial lines across chunk boundaries
- CLI file input uses 64 KiB raw `File.stream!/3` chunks; `WC.main/1` uses `IO.binstream/2` for raw stdin
- Invalid UTF-8 is normalized with `String.replace_invalid/1` for character counts; invalid-binary words use C-style ASCII whitespace
- `WC.run/1` uses a text stream so ExUnit `capture_io` can provide stdin
- Directories are reported to stderr and skipped while remaining files continue
