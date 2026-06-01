# wcx

An Elixir implementation of the Unix `wc` command line utility.

## Build

```sh
mix escript.build
```

This produces a `wc` binary in the project root.

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
