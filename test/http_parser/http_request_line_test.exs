defmodule HttpRequestLineTest do
  use ExUnit.Case
  alias HttpParser.HttpRequestLine
  doctest HttpRequestLine

  test "parse valid GET" do
    {:ok, res} = HttpRequestLine.parse("GET / HTTP/1.1")
    assert(res.method == :get)
    assert(res.uri.path == "/")
    assert(res.version == "HTTP/1.1")
  end

  test "parse valid POST" do
    {:ok, res} = HttpRequestLine.parse("POST http://127.0.0.1/user HTTP/1.1")
    assert(res.method == :post)
    assert(res.uri.path == "/user")
    assert(res.version == "HTTP/1.1")
  end

  test "parse unknown method" do
    {:error, :unknown_method} = HttpRequestLine.parse("WRONG 127.0.0.1/users HTTP/1.1")
  end

  test "parse malformed" do
    {:error, :malformed} = HttpRequestLine.parse("POST 127.0.0.1/users")
  end
end
