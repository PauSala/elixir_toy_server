defmodule HttpParser.HttpRequestLine do
  alias HttpParser.HttpRequestLine

  defstruct method: nil,
            uri: %URI{},
            version: nil

  def parse(line) do
    regex = ~r/^(?<method>[A-Z]+) (?<uri>\S+) (?<version>HTTP\/\d\.\d)$/

    case Regex.named_captures(regex, line) do
      %{"method" => method_str, "uri" => uri, "version" => version} ->
        with {:ok, method} <- method_atom(method_str),
             uri <- URI.parse(uri) do
          {:ok, %HttpRequestLine{method: method, uri: uri, version: version}}
        end

      nil ->
        {:error, :malformed}
    end
  end

  def method_atom("GET"), do: {:ok, :get}
  def method_atom("POST"), do: {:ok, :post}
  def method_atom("PUT"), do: {:ok, :put}
  def method_atom("DELETE"), do: {:ok, :delete}
  def method_atom("PATCH"), do: {:ok, :patch}
  def method_atom("HEAD"), do: {:ok, :head}
  def method_atom("OPTIONS"), do: {:ok, :options}
  def method_atom(_), do: {:error, :unknown_method}
end
