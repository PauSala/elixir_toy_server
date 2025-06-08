defmodule HttpHeadersTest do
  use ExUnit.Case
  alias HttpParser.HttpHeaders
  doctest HttpHeaders

  test "parse complete headers" do
    data =
      "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9\r\n" <>
        "Content-Length: 123" <>
        "\r\n\r\n" <>
        "rest-of-the-request"

    {:ok, headers, rest} = HttpHeaders.parse_lines(data)
    assert(length(headers) == 2)
    assert(rest == "rest-of-the-request")
  end

  test "parse missing headers end" do
    data =
      "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9\r\n" <>
        "Content-Length: 123" <>
        "\r\n"

    {:no_headers_end, headers, _} = HttpHeaders.parse_lines(data)
    assert(length(headers) == 2)
  end

  test "parse incomplete header end" do
    data =
      "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9\r\n" <>
        "Content-Length"

    {:incomplete_header, headers, rest} = HttpHeaders.parse_lines(data)
    assert(length(headers) == 1)
    assert(rest == "Content-Length")
  end

  test "parse no headers" do
    data =
      "\r\n" <> "rest-of-the-request"

    {:ok, headers, rest} = HttpHeaders.parse_lines(data)
    assert(length(headers) == 0)
    assert(rest == "rest-of-the-request")
  end

  test "parse lines, valid headers" do
    lines =
      [
        "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9",
        "Content-Length: 123",
        "Content-Type: application/json",
        "Set-Cookie: sessionId=abc123; Path=/; HttpOnly",
        "Set-Cookie: theme=light; Path=/",
        "Set-Cookie: lang=en-US; Path=/"
      ]

    headers = HttpHeaders.parse_headers(lines)
    assert(is_list(headers["set-cookie"]) == true)
    assert(headers["authorization"] == "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9")
  end
end
