defmodule KV.Supervisor do
  @moduledoc """
  Supervisor for the bucket Registry.
  """
  use Supervisor

  @spec start_link(any) :: :ignore | {:error, any} | {:ok, pid}
  @doc """
    Starts the KV Supervisor
  """
  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  # region [ callbacks ]
  @impl true
  @spec init(:ok) :: {:ok, {:supervisor.sup_flags(), [:supervisor.child_spec()]}} | :ignore
  @doc """
    Initialize the bucket registry
  """
  def init(:ok) do
    children = [
      # Using a DynamicSupervisor for KV.Bucket will ensure that if a bucket crashes,
      # it does not crash the registry
      {DynamicSupervisor, name: KV.BucketSupervisor, strategy: :one_for_one},
      {KV.Registry, name: KV.Registry}
    ]

    # ~~one-for-one means that if a child dies, it will be the only one restarted
    # Supervisor init will traverse the list of children invoking child_spec/1
    # GenServer, Agent, Supervisor etc. all define a default child_spec/1
    # Then each child is started in order, using the start: defined in its child_spec~~
    #
    # one-for-all means that if a child dies, all children will be restarted, in the
    # defined order. Now that we are using a DynamicSupervisor for buckets, this is
    # the more suitable option.
    Supervisor.init(children, strategy: :one_for_all)
  end

  # endregion [ callbacks ]
end
