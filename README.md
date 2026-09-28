# wcx

An Elixir implementation of the Unix `wc` command line utility.

## Build

Two flavors, both from the same code.

### Escript

```sh
mix escript.build
```

This produces a `wc` binary in the project root. It needs Erlang/OTP on the
target machine and is the fastest way to get a working binary while hacking on
the project.

### Standalone binaries

```sh
MIX_ENV=prod mix release --overwrite
```

This wraps the application with [Burrito](https://github.com/burrito-elixir/burrito)
and writes one self-contained binary per target to `burrito_out/`. Nothing needs
to be installed on the target machine: the Erlang runtime travels inside the
binary, which is why they are roughly ten times larger than the escript.

| Binary                                  | Target                |
|-----------------------------------------|-----------------------|
| `burrito_out/wc_macos_arm64`            | macOS, Apple Silicon  |
| `burrito_out/wc_macos_x86_64`           | macOS, Intel          |
| `burrito_out/wc_linux_x86_64`           | Linux, x86-64         |
| `burrito_out/wc_linux_arm64`            | Linux, ARM64          |
| `burrito_out/wc_windows_x86_64.exe`     | Windows, x86-64       |

Build requirements:

- Zig **0.16.0** exactly, Burrito refuses to build with any other version
- `xz`
- `7zz` or `7z` (only needed for the Windows target, which unpacks the Windows
  Erlang installer)
- macOS and Linux hosts can build all five targets. Windows hosts cannot, use
  WSL.

Build a single target with `BURRITO_TARGET`:

```sh
MIX_ENV=prod BURRITO_TARGET=linux_x86_64 mix release --overwrite
```

The first run of a binary unpacks its payload into the system application
directory, later runs reuse it. Each binary carries these maintenance commands:

```sh
./wc_macos_arm64 maintenance directory   # where the payload lives
./wc_macos_arm64 maintenance meta        # build metadata, including the ERTS
./wc_macos_arm64 maintenance uninstall   # remove the unpacked payload
```

macOS Gatekeeper blocks the unsigned binaries until they are either code signed
or explicitly allowed.

The ERTS version is pinned in `lib/wc/release/erts_resolver.ex` to the `X.Y`
release of the Erlang that built the payload, so a host patch level such as
29.1.1 does not ask for a tarball that does not exist. It has to track the host
Erlang, because Burrito keeps the payload's own ERTS beams and only swaps the
binaries and NIFs: bundle a different minor and the kernel fails to boot. Build
on the same Erlang minor you intend to ship, or pin that minor in CI.

## Usage

```sh
./wc [OPTION]... [FILE]...
```

Read from stdin when no files are given:

```sh
echo "hello world" | ./wc
```

## Options

| Flag | Long          | Description                 |
|------|---------------|-----------------------------|
| `-l` | `--lines`     | print the newline counts    |
| `-w` | `--words`     | print the word counts       |
| `-c` | `--bytes`     | print the byte counts       |
| `-m` | `--chars`     | print the character counts  |
| `-L` | `--longest`   | print the longest line length |
| `-h` | `--help`      | display help and exit       |

Default (no flags) is equivalent to `-lwc`.

## Reference

https://en.wikipedia.org/wiki/Wc_(Unix)
