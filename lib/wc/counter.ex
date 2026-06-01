defmodule WC.Counter do
  @moduledoc """
  Counts lines, words, bytes, characters, and longest line from a stream.

  Each chunk in the stream is a binary line (with or without trailing newline).
  """

  defstruct [:lines, :words, :bytes, :chars, :longest]

  @doc """
  Counts statistics from a stream of lines.

  The stream should emit binaries that are lines of text (may or may not
  include a trailing newline). Returns a `%WC.Counter{}` struct.
  """
  def count(stream) do
    initial = %WC.Counter{lines: 0, words: 0, bytes: 0, chars: 0, longest: 0}

    Enum.reduce(stream, initial, &process_line/2)
  end

  defp process_line(line, acc) do
    has_nl = String.ends_with?(line, "\n")
    byte_size = byte_size(line)

    stripped =
      if has_nl do
        part_size = byte_size - 1
        if part_size >= 0, do: binary_part(line, 0, part_size), else: ""
      else
        line
      end

    char_count = String.length(stripped)

    %WC.Counter{
      lines: acc.lines + if(has_nl, do: 1, else: 0),
      words: acc.words + count_words(stripped),
      bytes: acc.bytes + byte_size,
      chars: acc.chars + char_count + if(has_nl, do: 1, else: 0),
      longest: max(acc.longest, char_count)
    }
  end

  defp count_words(str) do
    str |> String.split() |> length()
  end
end
