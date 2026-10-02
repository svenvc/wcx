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

The macOS binaries are unsigned. Copies fetched with `curl` run fine because
`curl` sets no quarantine attribute; only a browser download marks the file
quarantined, which is what Gatekeeper blocks. See the macOS note in the
Releases section.

The ERTS version is pinned in `lib/wc/release/erts_resolver.ex` to the `X.Y`
release of the Erlang that built the payload, so a host patch level such as
29.1.1 does not ask for a tarball that does not exist. It has to track the host
Erlang, because Burrito keeps the payload's own ERTS beams and only swaps the
binaries and NIFs: bundle a different minor and the kernel fails to boot. Build
on the same Erlang minor you intend to ship, or pin that minor in CI.

## Dev container

Opening the folder in a dev container gives you the whole build toolchain:
Elixir 1.20.4 on OTP 29, Zig 0.16.0, `xz`, `7z`, the Expert language server and
OpenCode. Hex, rebar3 and the deps are installed when the container is created,
so `mix test` and `MIX_ENV=prod mix release --overwrite` work right away.

To build the image without an editor:

```sh
podman build -t wcx-dev .devcontainer
```

Binaries built inside the container bundle the OTP 29 ERTS, so treat them as
testing artifacts: releases are built by CI on OTP 28, and Burrito keeps the ERTS
of the Erlang that built the payload. See the ERTS note above.

## Releases

Tagging a version on GitHub publishes a release with the binaries attached:

```sh
git tag v0.2.0 && git push origin-github v0.2.0
```

`.github/workflows/release.yaml` rebuilds all five targets, smoke tests the Linux
binary, writes `burrito_out/checksums.txt` with the SHA-256 digests, and
attaches everything to a GitHub Release with auto-generated notes. The release
assets are public and permanent, unlike the CI artifacts.

Install on macOS or Linux with curl, which runs the binary without Gatekeeper
friction:

```sh
curl -L -o ~/.local/bin/wc https://github.com/svenvc/wcx/releases/download/v0.2.0/wc_macos_arm64
chmod +x ~/.local/bin/wc
```

Pick the asset matching your platform (`wc_macos_x86_64`, `wc_linux_arm64`,
`wc_windows_x86_64.exe`, ...). A browser download on macOS sets the quarantine
attribute, which stops the binary until it is released:

```sh
xattr -d com.apple.quarantine wc
```

or right-click the file in Finder and choose **Open**.

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
