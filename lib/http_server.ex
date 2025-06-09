defmodule HttpServer do
  require Logger

  def accept(port) do
    # The options below mean:
    #
    # 1. `:binary` - receives data as binaries (instead of lists)
    # 2. `packet: :line` - receives data line by line
    # 3. `active: false` - blocks on `:gen_tcp.recv/2` until data is available
    # 4. `reuseaddr: true` - allows us to reuse the address if the listener crashes
    #
    {:ok, socket} =
      :gen_tcp.listen(port, [:binary, packet: :raw, active: false, reuseaddr: true])

    Logger.info("Accepting connections on port #{port}")
    loop_acceptor(socket)
  end

  defp loop_acceptor(socket) do
    {:ok, client} = :gen_tcp.accept(socket)
    {:ok, pid} = Task.Supervisor.start_child(HttpServer.TaskSupervisor, fn -> serve(client) end)
    :ok = :gen_tcp.controlling_process(client, pid)
    loop_acceptor(socket)
  end

  defp serve(socket) do
    read_loop(socket)
  end

  defp read_loop(socket) do
    req_parser = HttpParser.new()

    case do_read(socket, req_parser) do
      {:ok, _} ->
        write_line(default_ok_response(), socket)
        read_loop(socket)

      {:error, reason} ->
        IO.puts(reason)
        :closed
    end
  end

  defp do_read(socket, parser) do
    case :gen_tcp.recv(socket, 0) do
      {:ok, data} ->
        parser = HttpParser.parse(parser, data)

        case parser.status do
          :end ->
            IO.inspect(parser)
            {:ok, parser}

          :error ->
            IO.puts(parser.error)
            write_line(default_error_response(), socket)
            {:error, :parser_error}

          _ ->
            do_read(socket, parser)
        end

      {:error, :closed} ->
        IO.puts("Client closed the connection")
        {:error, :closed}

      {:error, reason} ->
        IO.puts("Socket error: #{inspect(reason)}")
        write_line(default_error_response(), socket)
        {:error, reason}
    end
  end

  defp write_line(line, socket) do
    :gen_tcp.send(socket, line)
  end

  defp default_ok_response() do
    "HTTP/1.1 200 OK\r\n" <>
      "Content-Type: text/plain\r\n" <>
      "Content-Length: 5\r\n\r\n" <>
      "Hello\r\n"
  end

  defp default_error_response() do
    body = "Oops!\n"

    "HTTP/1.1 500 Internal Server Error\r\n" <>
      "Content-Type: text/plain\r\n" <>
      "Content-Length: #{byte_size(body)}\r\n\r\n" <>
      body
  end
end
