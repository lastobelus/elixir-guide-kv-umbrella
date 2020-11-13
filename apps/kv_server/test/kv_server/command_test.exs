defmodule KVServer.CommandTest do
  @moduledoc """
  Tests for KVServer.Command
  """
  use ExUnit.Case, async: true
  doctest KVServer.Command

  setup context do
    # start_supervised! is an EXUnit helper that guarantees the process
    # will be properly stopped & started between test runs
    _ = start_supervised!({KV.Registry, name: context.test})
    %{registry: context.test}
  end

  @tag :distributed
  test "creates a bucket", %{registry: registry} do
    assert KV.Registry.lookup(registry, "shopping") == :error

    assert {:ok, "OK\r\n"} = KVServer.Command.run({:create, "shopping"}, registry)
    assert {:ok, _bucket} = KV.Registry.lookup(registry, "shopping")
  end

  @tag :distributed
  test "gets a key ", %{registry: registry} do
    bucket = KV.Registry.create(registry, "shopping")
    KV.Bucket.put(bucket, "milk", "7")

    assert {:ok, "7\r\nOK\r\n"} = KVServer.Command.run({:get, "shopping", "milk"}, registry)
  end

  @tag :distributed
  test "puts a key ", %{registry: registry} do
    bucket = KV.Registry.create(registry, "shopping")

    assert {:ok, "OK\r\n"} = KVServer.Command.run({:put, "shopping", "milk", 8}, registry)
    assert KV.Bucket.get(bucket, "milk") == 8
  end

  @tag :distributed
  test "deletes a key", %{registry: registry} do
    bucket = KV.Registry.create(registry, "shopping")
    KV.Bucket.put(bucket, "milk", "9")

    assert {:ok, "OK\r\n"} = KVServer.Command.run({:delete, "shopping", "milk"}, registry)
    assert KV.Bucket.get(bucket, "milk") == nil
  end
end
