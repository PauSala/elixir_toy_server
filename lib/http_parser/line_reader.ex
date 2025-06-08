defmodule HttpParser.LineReader do
  @doc """
  Reads the first line (up to CRLF) from a binary.
  Returns {:ok, line, buffer} if a line is found,
  or {:incomplete, accumulated_data} if no CRLF is found.
  """
  def read_line(data) when is_binary(data) do
    case String.split(data, "\r\n", parts: 2) do
      [line, rest_data] ->
        {:ok, line, rest_data}

      [line] ->
        {:incomplete, line}

      [] ->
        {:incomplete, data}
    end
  end
end
