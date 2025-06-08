defmodule HttpParserTest do
  use ExUnit.Case
  doctest HttpParser

  test "test valid GET" do
    parser = HttpParser.new()

    request =
      "GET /index.html HTTP/1.1\r\n"

    %HttpParser{status: status, request_line: request_line} = HttpParser.parse(parser, request)
    assert(request_line.method == :get)
    assert(status == :headers)
  end

  test "test incomplete POST" do
    parser = HttpParser.new()

    request =
      "POST /index.html HTTP/1"

    parser = HttpParser.parse(parser, request)
    assert(parser.status == :initial)

    request =
      ".1\r\n" <>
        "Content-Length: 399"

    %HttpParser{status: status, request_line: request_line, buffer: rd} =
      HttpParser.parse(parser, request)

    assert(request_line.method == :post)
    assert(status == :headers)
    assert(rd == "Content-Length: 399")
  end

  test "test incomplete headers" do
    parser = HttpParser.new()

    request =
      "POST /index.html HTTP/1.1\r\n" <>
        "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9\r\n" <>
        "Content-Length: 123" <>
        "\r\n"

    %HttpParser{status: status, headers: headers} = HttpParser.parse(parser, request)
    assert(status == :headers)
    assert(headers["authorization"] == "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9")
    assert(headers["content-length"] == "123")
  end

  test "test incomplete header" do
    parser = HttpParser.new()

    request =
      "POST /index.html HTTP/1.1\r\n" <>
        "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9\r\n" <>
        "Content-Length:"

    %HttpParser{status: status, headers: headers, buffer: rd} =
      HttpParser.parse(parser, request)

    assert(status == :headers)
    assert(headers["authorization"] == "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9")
    assert(rd == "Content-Length:")
  end

  test "test full headers" do
    parser = HttpParser.new()

    request =
      "POST /index.html HTTP/1.1\r\n" <>
        "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9\r\n" <>
        "Content-Length: 123" <>
        "\r\n" <>
        "\r\n"

    %HttpParser{status: status, headers: headers} = HttpParser.parse(parser, request)
    assert(status == :body)
    assert(headers["authorization"] == "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9")
    assert(headers["content-length"] == "123")
  end

  test "no headers" do
    parser = HttpParser.new()

    request =
      "GET /index.html HTTP/1.1\r\n" <>
        "\r\n"

    %HttpParser{status: status, headers: headers} = HttpParser.parse(parser, request)
    assert(status == :end)
    assert(map_size(headers) == 0)
  end

  test "test incremental headers" do
    parser = HttpParser.new()

    request =
      "POST /index.html HTTP/1.1\r\n" <>
        "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9\r\n" <>
        "Content-Length:"

    parser =
      HttpParser.parse(parser, request)

    assert(parser.status == :headers)
    assert(parser.headers["authorization"] == "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9")
    assert(parser.buffer == "Content-Length:")

    request =
      " 123\r\n\r\n" <>
        "remaining-request"

    %HttpParser{status: status, headers: headers, buffer: rd} =
      HttpParser.parse(parser, request)

    assert(status == :body)
    assert(headers["authorization"] == "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9")
    assert(headers["content-length"] == "123")
    assert(rd == "remaining-request")
  end

  test "test body" do
    parser = HttpParser.new()

    request =
      "POST /index.html HTTP/1.1\r\n" <>
        "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9\r\n" <>
        "Content-Length: 24" <>
        "\r\n" <>
        "\r\n" <>
        ~S'{"user":"john", "age":21}'

    parser = HttpParser.parse(parser, request)
    IO.inspect(parser)
  end
end
