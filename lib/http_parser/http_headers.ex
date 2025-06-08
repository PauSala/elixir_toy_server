defmodule HttpParser.HttpHeaders do
  @header_name_regex ~r/^[!#$%&'*+\-.^_`|~0-9A-Za-z]+\z/
  @header_value_regex ~r/^[\t\x20-\x7E]*\z/

  def parse_lines(data) do
    lines(data, [])
  end

  defp lines("", arr) do
    {:no_headers_end, Enum.reverse(arr), ""}
  end

  defp lines(data, arr) do
    as_list = String.split(data, "\r\n", parts: 2)

    case as_list do
      ["" | []] ->
        {:ok, Enum.reverse(arr), ""}

      ["" | tail] ->
        {:ok, Enum.reverse(arr), hd(tail)}

      [next | []] ->
        {:incomplete_header, arr, next}

      [next | tail] ->
        arr = [next] ++ arr
        lines(hd(tail), arr)
    end
  end

  @doc """
  Parse headers assumming single lines are provided.
  """
  def parse_headers(lines) do
    Enum.reduce_while(lines, %{}, fn line, acc ->
      case String.split(line, ":", parts: 2) do
        [name, value] ->
          if !valid_header_name?(name) or !valid_header_value?(value) do
            {:halt, {:error, :invalid_header}}
          else
            updated =
              Map.update(acc, String.downcase(name), String.trim(value), fn existing ->
                List.wrap(existing) ++ [String.trim(value)]
              end)

            {:cont, updated}
          end

        _ ->
          {:halt, {:error, :invalid_header}}
      end
    end)
  end

  def valid_header_name?(name) do
    Regex.match?(@header_name_regex, name)
  end

  def valid_header_value?(value) do
    Regex.match?(@header_value_regex, value)
  end
end
