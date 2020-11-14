defmodule KV.RouterTest do
  @moduledoc """
  Test reading & using the routing table.
  Requires separately running two kv nodes:
  `cd apps/kv`
  `iex --sname a-to-m -S mix`
  `iex --sname n-to-z -S mix`
  """
  use ExUnit.Case

  setup_all do
    current = Application.get_env(:kv, :routing_table)

    Application.put_env(:kv, :routing_table, [
      {?a..?m, :"a-to-m@htulo"},
      {?n..?z, :"n-to-z@htulo"}
    ])

    on_exit(fn -> Application.put_env(:kv, :routing_table, current) end)
  end

  @tag :distributed
  test "route requests across nodes" do
    assert KV.Router.route("hello", Kernel, :node, []) ==
             :"a-to-m@htulo"

    assert KV.Router.route("world", Kernel, :node, []) ==
             :"n-to-z@htulo"
  end

  test "raises on unknown entries" do
    assert_raise RuntimeError, ~r/could not find entry/, fn ->
      KV.Router.route(<<0>>, Kernel, :node, [])
    end
  end
end
