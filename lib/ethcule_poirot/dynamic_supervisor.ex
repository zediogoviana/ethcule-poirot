defmodule EthculePoirot.DynamicSupervisor do
  @moduledoc false

  use DynamicSupervisor

  alias EthculePoirot.{AddressExplorer, NetworkExplorer}

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)

    DynamicSupervisor.start_child(__MODULE__, {NetworkExplorer, %{}})
  end

  def start_address_explorer(eth_address, depth) do
    spec = {AddressExplorer, %{eth_address: eth_address, depth: depth}}
    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
