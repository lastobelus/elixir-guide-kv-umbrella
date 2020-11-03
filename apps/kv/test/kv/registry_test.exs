defmodule KV.RegistryTest do
  @moduledoc """
  Tests for the Bucket Registry, which is a GenServer
  """
  use ExUnit.Case, async: true

  setup context do
    # start_supervised! is an EXUnit helper that guarantees the process
    # will be properly stopped & started between test runs
    _ = start_supervised!({KV.Registry, name: context.test})
    %{registry: context.test}
  end

  test "spawns buckets", %{registry: registry} do
    assert KV.Registry.lookup(registry, "shopping") == :error

    KV.Registry.create(registry, "shopping")
    assert {:ok, bucket} = KV.Registry.lookup(registry, "shopping")

    KV.Bucket.put(bucket, "milk", 1)
    assert KV.Bucket.get(bucket, "milk") == 1
  end

  test "removes buckets on exit", %{registry: registry} do
    KV.Registry.create(registry, "shopping")
    {:ok, bucket} = KV.Registry.lookup(registry, "shopping")

    Agent.stop(bucket)

    ensure_stopped(registry)
    assert KV.Registry.lookup(registry, "shopping") == :error
  end

  test "removes bucket on crash", %{registry: registry} do
    KV.Registry.create(registry, "shopping")
    {:ok, bucket} = KV.Registry.lookup(registry, "shopping")

    # Stop the bucket with non-normal reason
    Agent.stop(bucket, :shutdown)

    ensure_stopped(registry)
    assert KV.Registry.lookup(registry, "shopping") == :error
  end

  defp ensure_stopped(registry) do
    # Since lookup does not talk to the server, we need to send (any)
    # synchronous message to the server to ensure the `:DOWN` message
    # from the bucket dying has been processed.
    _ = KV.Registry.create(registry, "bogus")
  end
end
