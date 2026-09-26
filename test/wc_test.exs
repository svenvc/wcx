defmodule WCTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  describe "WC.Counter.count/1" do
    test "empty stream" do
      assert WC.Counter.count([]) == %WC.Counter{
               lines: 0,
               words: 0,
               bytes: 0,
               chars: 0,
               longest: 0
             }
    end

    test "single line without newline" do
      assert WC.Counter.count(["hello"]) == %WC.Counter{
               lines: 0,
               words: 1,
               bytes: 5,
               chars: 5,
               longest: 5
             }
    end

    test "single line with newline" do
      assert WC.Counter.count(["hello\n"]) == %WC.Counter{
               lines: 1,
               words: 1,
               bytes: 6,
               chars: 6,
               longest: 5
             }
    end

    test "multiple lines" do
      assert WC.Counter.count(["hello\n", "world\n"]) == %WC.Counter{
               lines: 2,
               words: 2,
               bytes: 12,
               chars: 12,
               longest: 5
             }
    end

    test "multiple lines in a single chunk" do
      assert WC.Counter.count(["hello\nworld\n"]) == %WC.Counter{
               lines: 2,
               words: 2,
               bytes: 12,
               chars: 12,
               longest: 5
             }
    end

    test "multiple words per line" do
      assert WC.Counter.count(["hello world\n"]) == %WC.Counter{
               lines: 1,
               words: 2,
               bytes: 12,
               chars: 12,
               longest: 11
             }
    end

    test "empty line" do
      assert WC.Counter.count(["\n"]) == %WC.Counter{
               lines: 1,
               words: 0,
               bytes: 1,
               chars: 1,
               longest: 0
             }
    end

    test "empty lines" do
      assert WC.Counter.count(["\n", "\n"]) == %WC.Counter{
               lines: 2,
               words: 0,
               bytes: 2,
               chars: 2,
               longest: 0
             }
    end

    test "file ending without newline" do
      assert WC.Counter.count(["hello\n", "world"]) == %WC.Counter{
               lines: 1,
               words: 2,
               bytes: 11,
               chars: 11,
               longest: 5
             }
    end

    test "file with only newline" do
      assert WC.Counter.count(["\n"]) == %WC.Counter{
               lines: 1,
               words: 0,
               bytes: 1,
               chars: 1,
               longest: 0
             }
    end

    test "words with extra whitespace" do
      assert WC.Counter.count(["hello   world\tfoo\n"]) == %WC.Counter{
               lines: 1,
               words: 3,
               bytes: 18,
               chars: 18,
               longest: 17
             }
    end

    test "unicode characters" do
      stream = ["héllo\n", "wörld\n"]
      result = WC.Counter.count(stream)
      assert result.lines == 2
      assert result.words == 2
      assert result.bytes == 14
      assert result.chars == 12
      assert result.longest == 5
    end

    test "invalid UTF-8 bytes" do
      result = WC.Counter.count([<<255, 195, 169, 10>>, <<0>>])

      assert result == %WC.Counter{
               lines: 1,
               words: 2,
               bytes: 5,
               chars: 4,
               longest: 2
             }
    end

    test "handles chunks split across lines" do
      result = WC.Counter.count(["hé", "llo\nwor", "ld\n"])

      assert result == %WC.Counter{
               lines: 2,
               words: 2,
               bytes: 13,
               chars: 12,
               longest: 5
             }
    end

    test "invalid UTF-8 words use byte whitespace" do
      result = WC.Counter.count([<<255, 194, 160, ?A, ?\n>>])

      assert result.words == 1
    end

    test "invalid UTF-8 words separate on ASCII whitespace" do
      assert WC.Counter.count([<<255, ?\s, ?A, ?\n>>]) == %WC.Counter{
               lines: 1,
               words: 2,
               bytes: 4,
               chars: 4,
               longest: 3
             }
    end

    test "longest line tracking" do
      stream = ["short\n", "a bit longer\n", "the longest line in this file\n"]
      result = WC.Counter.count(stream)
      assert result.lines == 3
      assert result.longest == 29
    end
  end

  describe "WC.parse_args/1" do
    test "no args uses default flags" do
      result = WC.parse_args([])
      assert result.flags.lines == true
      assert result.flags.words == true
      assert result.flags.bytes == true
      assert result.flags.chars == false
      assert result.flags.longest == false
      assert result.files == []
    end

    test "single file" do
      result = WC.parse_args(["file.txt"])
      assert result.files == ["file.txt"]
      assert result.flags.lines == true
    end

    test "flag overrides default" do
      result = WC.parse_args(["-l"])
      assert result.flags.lines == true
      assert result.flags.words == false
      assert result.flags.bytes == false
      assert result.flags.chars == false
      assert result.flags.longest == false
    end

    test "multiple flags" do
      result = WC.parse_args(["-lw"])
      assert result.flags.lines == true
      assert result.flags.words == true
      assert result.flags.bytes == false
    end

    test "long flag names" do
      result = WC.parse_args(["--lines", "--words", "--bytes"])
      assert result.flags.lines == true
      assert result.flags.words == true
      assert result.flags.bytes == true
    end

    test "-L longest flag" do
      result = WC.parse_args(["-L"])
      assert result.flags.longest == true
      assert result.flags.lines == false
    end

    test "files with flags" do
      result = WC.parse_args(["-l", "a.txt", "b.txt"])
      assert result.files == ["a.txt", "b.txt"]
      assert result.flags.lines == true
    end
  end

  describe "WC.run/1 output" do
    test "single file output" do
      content =
        capture_io(fn ->
          IO.puts(
            WC.run(%{
              flags: %{lines: true, words: true, bytes: true, chars: false, longest: false},
              files: ["test/fixtures/simple.txt"]
            })
          )
        end)

      assert content =~ ~r/1\s+2\s+12/
      assert content =~ ~r/simple\.txt/
    end

    test "single file -l only" do
      content =
        capture_io(fn ->
          IO.puts(
            WC.run(%{
              flags: %{lines: true, words: false, bytes: false, chars: false, longest: false},
              files: ["test/fixtures/simple.txt"]
            })
          )
        end)

      line_count = content |> String.trim() |> String.split() |> hd() |> String.to_integer()
      assert line_count == 1
    end

    test "multiple files shows totals" do
      content =
        capture_io(fn ->
          IO.puts(
            WC.run(%{
              flags: %{lines: true, words: true, bytes: true, chars: false, longest: false},
              files: ["test/fixtures/simple.txt", "test/fixtures/simple.txt"]
            })
          )
        end)

      assert content =~ ~r/total/
    end

    test "stdin mode" do
      content =
        capture_io([input: "hello world\n"], fn ->
          IO.puts(
            WC.run(%{
              flags: %{lines: true, words: true, bytes: true, chars: false, longest: false},
              files: []
            })
          )
        end)

      assert content =~ ~r/\s*1\s+2\s+12/
    end
  end

  describe "WC.run/1 edge cases" do
    test "empty file" do
      content =
        capture_io(fn ->
          IO.puts(
            WC.run(%{
              flags: %{lines: true, words: true, bytes: true, chars: false, longest: false},
              files: ["test/fixtures/empty.txt"]
            })
          )
        end)

      assert content =~ ~r/\s*0\s+0\s+0/
    end

    test "preserves bytes in long lines" do
      path = Path.join(System.tmp_dir!(), "wc-#{System.unique_integer([:positive])}.bin")
      content = :binary.copy(<<0>>, 1_000_000)
      File.write!(path, content)
      on_exit(fn -> File.rm(path) end)

      output =
        WC.run(%{
          flags: %{lines: true, words: true, bytes: true, chars: false, longest: false},
          files: [path]
        })

      assert output =~ "1000000"
    end

    test "missing file prints error" do
      stderr =
        capture_io(:stderr, fn ->
          capture_io(fn ->
            IO.puts(
              WC.run(%{
                flags: %{lines: true, words: true, bytes: true, chars: false, longest: false},
                files: ["nonexistent.txt"]
              })
            )
          end)
        end)

      assert stderr =~ "no such file or directory"
    end

    test "unreadable path reports formatted error" do
      {stdout, stderr} =
        with_io(:stderr, fn ->
          capture_io(fn ->
            IO.puts(
              WC.run(%{
                flags: %{lines: true, words: true, bytes: true, chars: false, longest: false},
                files: ["test/fixtures/simple.txt/nested.txt"]
              })
            )
          end)
        end)

      assert String.trim(stdout) == ""
      assert stderr =~ "wc: test/fixtures/simple.txt/nested.txt"
      assert stderr =~ "not a directory"
    end

    test "directory prints warning and is skipped" do
      {output, stderr} =
        with_io(:stderr, fn ->
          capture_io(fn ->
            IO.puts(
              WC.run(%{
                flags: %{lines: true, words: true, bytes: true, chars: false, longest: false},
                files: ["test/fixtures", "test/fixtures/simple.txt"]
              })
            )
          end)
        end)

      assert stderr =~ "wc: test/fixtures: read: Is a directory"
      assert output =~ ~r/simple\.txt/
    end

    test "-L flag output" do
      content =
        capture_io(fn ->
          IO.puts(
            WC.run(%{
              flags: %{lines: false, words: false, bytes: false, chars: false, longest: true},
              files: ["test/fixtures/simple.txt"]
            })
          )
        end)

      assert content =~ ~r/11/
      assert content =~ ~r/simple\.txt/
    end
  end

  describe "WC.main/1" do
    test "prints counts for a file argument" do
      output = capture_io(fn -> WC.main(["test/fixtures/simple.txt"]) end)

      assert output =~ ~r/1\s+2\s+12/
      assert output =~ ~r/simple\.txt/
    end

    test "prints counts for flag combinations" do
      output = capture_io(fn -> WC.main(["-lwL", "test/fixtures/simple.txt"]) end)

      assert output =~ ~r/1\s+2\s+11/
    end
  end
end
