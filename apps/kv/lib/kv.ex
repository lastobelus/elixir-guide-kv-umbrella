defmodule KV do
  @moduledoc """
  An application which provides a key value store.
  """
  use Application

  @impl true
  @doc """
    Initialize the app on startup
  """
  def start(_type, _args) do
    KV.Supervisor.start_link(name: KV.Supervisor)
  end
end
