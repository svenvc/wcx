defmodule WC.Counter do
  @moduledoc """
  Counts lines, words, bytes, characters, and longest line from a stream.

  Each chunk in the stream is binary data; newlines delimit lines.
  """

  defstruct [:lines, :words, :bytes, :chars, :longest]

  @doc """
  Counts statistics from a stream of binary chunks.

  Newline-delimited lines are accumulated across chunk boundaries. Returns a
  `%WC.Counter{}` struct.
  """
  def count(stream) do
    stream
    |> Enum.reduce(initial_state(), &process_chunk/2)
    |> finish()
  end

  defp initial_state do
    %{
      count: %WC.Counter{lines: 0, words: 0, bytes: 0, chars: 0, longest: 0},
      line: []
    }
  end

  defp process_chunk(chunk, state) do
    parts = :binary.split(chunk, "\n", [:global])
    state = %{state | count: %{state.count | bytes: state.count.bytes + byte_size(chunk)}}

    if ends_with_newline?(chunk) do
      parts
      |> remove_trailing_empty()
      |> process_complete_parts(state)
    else
      process_pending_parts(parts, state)
    end
  end

  defp remove_trailing_empty(parts) do
    case Enum.reverse(parts) do
      [<<>> | reversed] -> Enum.reverse(reversed)
      _ -> parts
    end
  end

  defp process_complete_parts([], state), do: state

  defp process_complete_parts([part], state) do
    state
    |> append_line(part)
    |> complete_line(true)
  end

  defp process_complete_parts([part | rest], state) do
    state =
      state
      |> append_line(part)
      |> complete_line(true)

    process_complete_parts(rest, state)
  end

  defp process_pending_parts([part], state), do: append_line(state, part)

  defp process_pending_parts([part | rest], state) do
    state =
      state
      |> append_line(part)
      |> complete_line(true)

    process_pending_parts(rest, state)
  end

  defp append_line(state, part), do: %{state | line: [part | state.line]}

  defp ends_with_newline?(chunk) do
    size = byte_size(chunk)
    size > 0 and binary_part(chunk, size - 1, 1) == "\n"
  end

  defp complete_line(state, newline?) do
    line = state.line |> Enum.reverse() |> IO.iodata_to_binary()
    normalized = String.replace_invalid(line)
    char_count = String.length(normalized)
    count = state.count

    count = %{
      count
      | lines: count.lines + if(newline?, do: 1, else: 0),
        words: count.words + count_words(line),
        chars: count.chars + char_count + if(newline?, do: 1, else: 0),
        longest: max(count.longest, char_count)
    }

    %{state | count: count, line: []}
  end

  defp finish(%{line: []} = state), do: state.count
  defp finish(state), do: state |> complete_line(false) |> Map.fetch!(:count)

  defp count_words(line) do
    if String.valid?(line) do
      line |> String.split() |> length()
    else
      count_binary_words(line)
    end
  end

  defp count_binary_words(line), do: count_binary_words(line, 0, false)

  defp count_binary_words(<<>>, words, _in_word), do: words

  defp count_binary_words(<<byte, rest::binary>>, words, in_word) do
    if whitespace?(byte) do
      count_binary_words(rest, words, false)
    else
      count_binary_words(rest, words + if(in_word, do: 0, else: 1), true)
    end
  end

  defp whitespace?(byte) when byte in [9, 10, 11, 12, 13, 32], do: true
  defp whitespace?(_byte), do: false
end
