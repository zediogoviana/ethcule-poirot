defmodule Address do
  @moduledoc false

  defstruct [:eth_address, :contract, :transactions]

  @type t :: %__MODULE__{
          eth_address: String.t() | nil,
          contract: boolean() | nil,
          transactions: list(Transaction.t()) | nil
        }
end
