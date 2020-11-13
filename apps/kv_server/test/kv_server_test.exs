defmodule KVServerTest do
  @moduledoc """
  Integration tests using a TCP client & testing the whole application stack
  """
  use ExUnit.Case

  @moduletag :capture_log

  # because our tests rely on the app's global state, the app must be
  # restarted for each test
  setup do
    Application.stop(:kv)
    :ok = Application.start(:kv)
  end

  # use multiple setup blocks to separate concerns
  setup do
    opts = [:binary, packet: :line, active: false]
    # start a tcp client. The socket will be closed automatically, no
    # need for a teardown function.
    {:ok, socket} = :gen_tcp.connect('localhost', 4040, opts)
    %{socket: socket}
  end

  # Integration tests combine multiple concerns, testing a flow.
  # Because of the overhead involved with each test, it is often better
  # to use a single test to test multiple related paths through the app
  # then to break it up into multiple focused tests
  @tag :distributed
  test "server interaction", %{socket: socket} do
    assert send_and_recv(socket, "UNKNOWN shopping\r\n") ==
             "UNKNOWN COMMAND\r\n"

    assert send_and_recv(socket, "GET shopping eggs\r\n") ==
             "NOT FOUND\r\n"

    assert send_and_recv(socket, "CREATE shopping\r\n") ==
             "OK\r\n"

    assert send_and_recv(socket, "PUT shopping eggs 3\r\n") ==
             "OK\r\n"

    # GET returns two lines
    assert send_and_recv(socket, "GET shopping eggs\r\n") == "3\r\n"
    assert send_and_recv(socket, "") == "OK\r\n"
  end

  defp send_and_recv(socket, command) do
    :ok = :gen_tcp.send(socket, command)
    {:ok, data} = :gen_tcp.recv(socket, 0, 1000)
    data
  end
end
