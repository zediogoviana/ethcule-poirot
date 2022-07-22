defmodule EthculePoirot.DynamicSupervisor do
  @moduledoc false

  use DynamicSupervisor

  alias EthculePoirot.{AddressExplorer, NetworkExplorer}

  @spec start_link(list()) :: any()
  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)

    DynamicSupervisor.start_child(__MODULE__, {NetworkExplorer, %{}})
  end

  @spec start_address_explorer(String.t(), pos_integer(), atom()) :: any()
  def start_address_explorer(eth_address, depth, api_handler) do
    spec =
      {AddressExplorer,
       %{
         eth_address: eth_address,
         depth: depth,
         api_handler: api_handler
       }}

    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
