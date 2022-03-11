defmodule Neo4j.Supervisor do
  @moduledoc false

  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  @impl true
  def init(:ok) do
    children = [
      {Bolt.Sips, Application.get_env(:bolt_sips, Bolt)},
      {Neo4j.Client, []}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
