defmodule KVServer do
  @moduledoc """
  Documentation for `KVServer`.
  """
  require Logger

  @doc """
    Starts a gen_tcp server on `port`, for creating/reading key-value buckets in kv
  """
  def accept(port) do
    # The options below mean:
    #
    # 1. `:binary` — receives data as binaries (instead of lists)
    # 2. `packet:: :line` — receives data line by line
    # 3. `active: false` — blocks on `:gen_tcp.recv/2` until data is available
    # 4. `reuseaddr: true  — allows us to reuse the address if the listener crashes

    {:ok, socket} =
      :gen_tcp.listen(port, [
        :binary,
        packet: :line,
        active: false,
        reuseaddr: true
      ])

    Logger.info("Accepting connections on port #{port}")
    loop_acceptor(socket)
  end

  defp loop_acceptor(socket) do
    {:ok, client} = :gen_tcp.accept(socket)
    # serve each client in it's own task, using KVServer.TaskSupervisor to supervise them
    {:ok, pid} = Task.Supervisor.start_child(KVServer.TaskSupervisor, fn -> serve(client) end)
    # the task needs to become the "controlling process" of the client socket, so that
    # the acceptor won't bring down all clients if it crashes
    :ok = :gen_tcp.controlling_process(client, pid)
    # continue to accept clients
    loop_acceptor(socket)
  end

  defp serve(socket) do
    # without Elixir `with` construct, we would need nested case statement:
    # msg =
    #   case read_line(socket) do
    #     {:ok, data} ->
    #       case KVServer.Command.parse(data) do
    #         {:ok, command} ->
    #           KVServer.Command.run(command)

    #         {:error, _} = err ->
    #           err
    #       end

    #     {:error, _} = err ->
    #       err
    #   end

    # `with` runs each match in sequence, returning the
    # result of `do:` or the first result that doesn't match
    msg =
      with {:ok, data} <- read_line(socket),
           {:ok, command} <- KVServer.Command.parse(data),
           do: KVServer.Command.run(command, KV.Registry)

    write_line(socket, msg)
    serve(socket)
  end

  defp read_line(socket) do
    :gen_tcp.recv(socket, 0)
  end

  defp write_line(socket, {:ok, text}) do
    :gen_tcp.send(socket, text)
  end

  defp write_line(socket, {:error, :unknown_command}) do
    # Known error; write to the client
    :gen_tcp.send(socket, "UNKNOWN COMMAND\r\n")
  end

  defp write_line(socket, {:error, :not_found}) do
    # Bucket not found
    :gen_tcp.send(socket, "NOT FOUND\r\n")
  end

  defp write_line(_socket, {:error, :closed}) do
    # The connection, was closed; write to the client and exit
    exit(:shutdown)
  end

  defp write_line(socket, {:error, error}) do
    # Unknown error; write to the client and exit
    :gen_tcp.send(socket, "Error\r\n")
    exit(error)
  end
end
