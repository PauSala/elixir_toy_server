defmodule HttpParser do
  alias HttpParser.HttpRequestLine
  alias HttpParser.LineReader
  alias HttpParser.HttpHeaders

  defstruct status: :initial,
            request_line: HttpRequest,
            headers: %{},
            body: <<>>,
            parsed_len: 0,
            content_len: nil,
            buffer: <<>>,
            ended: false,
            error: nil

  @doc """
  Initializes a new parser state.
  """
  def new() do
    %HttpParser{}
  end

  @doc """
  Parses a chunk of data, returning a new parser state and any completed request.
  """
  def parse(%HttpParser{} = state, new_data) do
    data = state.buffer <> new_data

    case state.status do
      :initial ->
        parse_request_line(state, data)

      :headers ->
        parse_headers(state, data)

      :body ->
        parse_body(state, data)

      :error ->
        state

      true ->
        IO.puts("END")
        state
    end
  end

  defp parse_request_line(%HttpParser{} = state, data) do
    case LineReader.read_line(data) do
      {:incomplete, data} ->
        %{state | buffer: data}

      {:ok, line, rest} ->
        case HttpRequestLine.parse(line) do
          {:error, reason} ->
            %{state | status: :error, error: reason}

          {:ok, request_line} ->
            state = %{state | status: :headers, buffer: rest, request_line: request_line}
            parse(state, <<>>)
        end
    end
  end

  defp parse_headers(%HttpParser{} = state, data) do
    {h_state, lines, buffer} = HttpHeaders.parse_lines(data)

    case h_state do
      :ok ->
        headers = HttpHeaders.parse_headers(lines)
        merged = merge_headers(state.headers, headers)
        state = %{state | status: :body, headers: merged, buffer: buffer}
        parse(state, <<>>)

      _ ->
        headers = HttpHeaders.parse_headers(lines)
        merged = merge_headers(state.headers, headers)
        state = %{state | status: :headers, headers: merged, buffer: buffer}
        state
    end
  end

  defp merge_headers(old, new) do
    Map.merge(new, old, fn _key, value1, value2 ->
      List.wrap(value1) ++ List.wrap(value2)
    end)
  end

  defp parse_body(%HttpParser{} = state, data) do
    case state.content_len do
      nil ->
        case state.headers["content-length"] do
          nil ->
            method = state.request_line.method

            if !Enum.member?([:post, :put], method) do
              %{state | status: :end, ended: true}
            else
              %{state | status: :error, error: :no_content_len}
            end

          len ->
            case Integer.parse(len) do
              {num, ""} ->
                state = %{state | content_len: num}
                read_body(state, data)

              _ ->
                %{state | status: :error, error: :wrong_content_len}
            end
        end

      _ ->
        read_body(state, data)
    end
  end

  defp read_body(%HttpParser{} = state, data) do
    body = state.body <> data

    if byte_size(body) >= state.content_len do
      %{state | status: :end, ended: true, body: body, buffer: <<>>}
    else
      %{state | status: :body, body: body, buffer: <<>>}
    end
  end
end
