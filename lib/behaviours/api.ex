defmodule Behaviours.Api do
  @moduledoc false

  @callback initial_setup() :: :ok
  @callback transactions_for_address(String.t()) :: Address.t()
  @callback address_information(String.t()) :: Address.t()
end
