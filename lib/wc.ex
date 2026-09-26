defmodule WC do
  @moduledoc """
  `wc` — an Elixir implementation of the Unix word count utility.
  """

  @default_flags %{lines: true, words: true, bytes: true, chars: false, longest: false}
  @chunk_size 64 * 1024

  @doc """
  Escript entry point. Called by escript with command-line arguments.
  """
  def main(args) do
    config = parse_args(args)

    output =
      if config.files == [] do
        run_with_input(config, IO.binstream(:stdio, @chunk_size))
      else
        run(config)
      end

    IO.puts(output)
  end

  @doc """
  Parses command-line arguments into a map of flags and file list.
  """
  def parse_args(args) do
    result =
      OptionParser.parse!(args,
        switches: [
          lines: :boolean,
          words: :boolean,
          bytes: :boolean,
          chars: :boolean,
          longest: :boolean,
          help: :boolean
        ],
        aliases: [
          l: :lines,
          w: :words,
          c: :bytes,
          m: :chars,
          L: :longest,
          h: :help
        ]
      )

    parsed_keywords = elem(result, 0)
    files = elem(result, 1)

    parsed_map = Map.new(parsed_keywords, fn {k, v} -> {k, v} end)

    if parsed_map[:help] do
      print_help()
      System.halt(0)
    end

    known = [:lines, :words, :bytes, :chars, :longest]
    active = Map.take(parsed_map, known)

    flags =
      if Enum.any?(active, fn {_k, v} -> v end) do
        %{lines: false, words: false, bytes: false, chars: false, longest: false}
        |> Map.merge(active)
      else
        @default_flags
      end

    %{flags: flags, files: files}
  end

  @doc """
  Runs wc with the given configuration.
  Returns the formatted output string (without trailing newline).
  """
  def run(config), do: run_with_input(config, IO.stream(:stdio, :line))

  defp run_with_input(%{flags: flags, files: []}, stream) do
    count = WC.Counter.count(stream)
    format_output(count, flags, "")
  end

  defp run_with_input(%{flags: flags, files: files}, _stream) do
    results =
      Enum.map(files, fn file ->
        case File.stat(file) do
          {:ok, %File.Stat{type: :directory}} ->
            IO.puts(:stderr, "wc: #{file}: read: Is a directory")
            nil

          {:ok, _stat} ->
            stream = File.stream!(file, @chunk_size, [:raw, :binary])
            count = WC.Counter.count(stream)
            {file, count}

          {:error, :enoent} ->
            IO.puts(:stderr, "wc: #{file}: no such file or directory")
            nil

          {:error, reason} ->
            IO.puts(:stderr, "wc: #{file}: #{:file.format_error(reason)}")
            nil
        end
      end)
      |> Enum.reject(&is_nil/1)

    output =
      results
      |> Enum.map_join("\n", fn {file, count} ->
        format_output(count, flags, file)
      end)

    if length(results) > 1 do
      totals =
        Enum.reduce(results, %WC.Counter{lines: 0, words: 0, bytes: 0, chars: 0, longest: 0}, fn
          {_file, c}, acc ->
            %WC.Counter{
              lines: acc.lines + c.lines,
              words: acc.words + c.words,
              bytes: acc.bytes + c.bytes,
              chars: acc.chars + c.chars,
              longest: max(acc.longest, c.longest)
            }
        end)

      output <> "\n" <> format_output(totals, flags, "total")
    else
      output
    end
  end

  defp format_output(count, flags, label) do
    columns = []
    columns = if flags.lines, do: columns ++ [count.lines], else: columns
    columns = if flags.words, do: columns ++ [count.words], else: columns
    columns = if flags.bytes, do: columns ++ [count.bytes], else: columns
    columns = if flags.chars, do: columns ++ [count.chars], else: columns
    columns = if flags.longest, do: columns ++ [count.longest], else: columns

    numbers = columns |> Enum.map_join(" ", &format_number/1)

    if label == "" do
      numbers
    else
      numbers <> " " <> label
    end
  end

  defp format_number(n) do
    String.pad_leading(Integer.to_string(n), 7)
  end

  defp print_help do
    IO.puts(:stderr, """
    Usage: wc [OPTION]... [FILE]...
    Print newline, word, and byte counts for each FILE.

      -c, --bytes    print the byte counts
      -l, --lines    print the newline counts
      -L, --longest  print the length of the longest line
      -m, --chars    print the character counts
      -w, --words    print the word counts
      -h, --help     display this help and exit
    """)
  end
end
