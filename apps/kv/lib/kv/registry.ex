defmodule KV.Registry do
  @moduledoc """
  Implements a bucket registry, using GenServer
  """
  use GenServer

  @type registry :: atom | pid | {atom, any} | {:via, atom, any}

  ## Client API

  @spec start_link(any) :: :ignore | {:error, any} | {:ok, pid}
  @doc """
  Starts the registry with the given options.

  `:name` is always required
  """
  def start_link(opts) do
    name = Keyword.fetch!(opts, :name)
    GenServer.start_link(__MODULE__, name, opts)
  end

  @spec lookup(registry(), String.t()) :: :error | {:ok, pid}
  @doc """
    Looks up the bucket pid for `name` stored in `server`.

    Server references are cached in an ETS table

    Returns `{:ok, pid}` if the bucket exists, :error otherwise
  """
  def lookup(server, name) do
    case :ets.lookup(server, name) do
      [{^name, pid}] -> {:ok, pid}
      [] -> :error
    end
  end

  @spec create(registry(), String.t()) :: :ok
  @doc """
    Ensures there is a bucket associated with the given 'name' in 'server'.
  """
  def create(server, name) do
    GenServer.call(server, {:create, name})
  end

  # region [ callbacks ]

  @impl true
  def init(table_name) do
    names = :ets.new(table_name, [:named_table, read_concurrency: true])
    refs = %{}
    {:ok, {names, refs}}
  end

  @impl true
  @doc """
  Handle creating a bucket by name
  """
  def handle_call({:create, name}, _from, {names, refs}) do
    case lookup(names, name) do
      {:ok, pid} ->
        # third argument (`{names, refs}` is the resultant state)
        {:reply, pid, {names, refs}}

      :error ->
        {:ok, pid} = DynamicSupervisor.start_child(KV.BucketSupervisor, KV.Bucket)
        ref = Process.monitor(pid)
        refs = Map.put(refs, ref, name)
        :ets.insert(names, {name, pid})
        {:reply, pid, {names, refs}}
    end
  end

  @impl true
  @doc """
    Handle monitoring messages from bucket
  """
  def handle_info({:DOWN, ref, :process, _pid, _reason}, {names, refs}) do
    {name, refs} = Map.pop(refs, ref)
    :ets.delete(names, name)
    {:noreply, {names, refs}}
  end

  @impl true
  # Handle other monitoring messages we don't care about at present
  def handle_info(_msg, state) do
    {:noreply, state}
  end

  # endregion [callbacks]
end
