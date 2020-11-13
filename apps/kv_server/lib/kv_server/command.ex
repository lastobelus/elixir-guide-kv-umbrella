defmodule KVServer.Command do
  @moduledoc """
  Parse and run KV commands using :kv
  """
  @type command ::
          {:create, binary}
          | {:delete, binary, binary}
          | {:get, binary, binary}
          | {:put, binary, binary, binary}
  @type response :: {:error, :not_found} | {:ok, <<_::32, _::_*8>>}

  @spec parse(binary) ::
          {:error, :unknown_command}
          | {:ok, command()}
  @doc ~S"""
  Parses the given `line` into a command.

  ## Examples

      iex> KVServer.Command.parse("CREATE shopping\r\n")
      {:ok, {:create, "shopping"}}

      iex> KVServer.Command.parse("CREATE shopping \r\n")
      {:ok, {:create, "shopping"}}

      iex> KVServer.Command.parse("PUT shopping milk 1\r\n")
      {:ok, {:put, "shopping", "milk", "1"}}

      iex> KVServer.Command.parse("GET shopping milk\r\n")
      {:ok, {:get, "shopping", "milk"}}

  Unknown commands or commands with the wrong number of arguments return an error:

      iex> KVServer.Command.parse("UNKNOWN shopping\r\n")
      {:error, :unknown_command}

      iex> KVServer.Command.parse("GET shopping\r\n")
      {:error, :unknown_command}

  """
  def parse(line) do
    case String.split(line) do
      ["CREATE", bucket] -> {:ok, {:create, bucket}}
      ["GET", bucket, key] -> {:ok, {:get, bucket, key}}
      ["PUT", bucket, key, value] -> {:ok, {:put, bucket, key, value}}
      ["DELETE", bucket, key] -> {:ok, {:delete, bucket, key}}
      _ -> {:error, :unknown_command}
    end
  end

  @spec run(command(), atom() | pid()) :: response()
  @doc """
    Runs the given `command`.

    ## Examples

    iex>
  """
  # a bodiless function is used to declare and/or document the
  # default arguments for a multi-clause function
  def run(command, registry)

  def run({:create, bucket}, registry) do
    case KV.Router.route(bucket, KV.Registry, :create, [KV.Registry, bucket]) do
      pid when is_pid(pid) -> {:ok, "OK\r\n"}
      _ -> {:error, "FAILED TO CREATE BUCKET"}
    end

    KV.Registry.create(registry, bucket)
    {:ok, "OK\r\n"}
  end

  def run({:get, bucket, key}, registry) do
    lookup(bucket, registry, fn pid ->
      value = KV.Bucket.get(pid, key)
      {:ok, "#{value}\r\nOK\r\n"}
    end)
  end

  def run({:put, bucket, key, value}, registry) do
    lookup(bucket, registry, fn pid ->
      KV.Bucket.put(pid, key, value)
      {:ok, "OK\r\n"}
    end)
  end

  def run({:delete, bucket, key}, registry) do
    lookup(bucket, registry, fn pid ->
      KV.Bucket.delete(pid, key)
      {:ok, "OK\r\n"}
    end)
  end

  defp lookup(bucket, registry, callback) do
    case KV.Router.route(bucket, KV.Registry, :lookup, [registry, bucket]) do
      {:ok, pid} -> callback.(pid)
      :error -> {:error, :not_found}
    end
  end
end
