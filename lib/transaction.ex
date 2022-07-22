defmodule Transaction do
  @moduledoc false

  @enforce_keys [:hash, :to_address, :from_address, :value, :status]
  defstruct [:hash, :to_address, :from_address, :value, :status]

  @type t :: %__MODULE__{
          hash: String.t(),
          to_address: String.t(),
          from_address: String.t(),
          value: String.t(),
          status: String.t()
        }
end
