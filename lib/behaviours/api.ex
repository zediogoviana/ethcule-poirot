defmodule Behaviours.Api do
  @callback initial_setup() :: :ok
  @callback transactions_for_address(String.t()) :: any()
  @callback address_information(String.t()) :: any()
end
