defmodule KV.Bucket do
  @moduledoc """
  Implements an instance of a key-value store using Agent
  """
  # we use the `restart: :temporary` option to ensure that if a bucket
  # crashes, KV.BucketSupervisor does not start a new one as it would be
  # orphaned
  use Agent, restart: :temporary

  @type bucket :: atom | pid | {atom, any} | {:via, atom, any}

  @spec start_link(any) :: {:error, any} | {:ok, bucket()}
  @doc """
  Starts a new bucket.
  A start_link/1 function that accepts options is a standard convention
  """
  def start_link(_opts) do
    Agent.start_link(fn -> %{} end)
  end

  @doc """
  Gets a value from the `bucket` by `key`
  """
  @spec get(bucket(), atom) :: any
  def get(bucket, key) do
    Agent.get(bucket, &Map.get(&1, key))
  end

  @spec put(bucket(), atom, any) :: :ok
  @doc """
  Puts the `value` for the given `key` in the `bucket`.
  """
  def put(bucket, key, value) do
    Agent.update(bucket, &Map.put(&1, key, value))
  end

  @spec delete(bucket(), atom) :: any
  @doc """
  Deletes `key` from the bucket, returning it's value if it existed
  """
  def delete(bucket, key) do
    Agent.get_and_update(bucket, &Map.pop(&1, key))
  end
end
