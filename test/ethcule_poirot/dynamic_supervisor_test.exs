defmodule EthculePoirot.DynamicSupervisorTest do
  use ExUnit.Case
  alias EthculePoirot.DynamicSupervisor
  doctest EthculePoirot.DynamicSupervisor

  describe "start_link/1" do
    test "starts the dynamic supersivor and respective NetworkExplorer" do
      explorer_pid = Process.whereis(EthculePoirot.NetworkExplorer)

      assert Process.alive?(explorer_pid)
    end
  end

  describe "start_address_explorer/2" do
    test "adds an address explorer GenServer to the dynamic sup" do
      api_adapter = Adapters.Api.Blockscout
      assert {:ok, _pid} = DynamicSupervisor.start_address_explorer("0x123", 2, api_adapter)
    end
  end
end
