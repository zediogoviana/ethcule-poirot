defmodule Neo4j.Cypher do
  @moduledoc false

  def prepared_statement(query_string, variables \\ []) when is_list(variables) do
    prepared_vars =
      Enum.map(variables, fn {key, value} ->
        case value do
          nil -> {key, ""}
          _ -> {key, String.replace(value, "'", "\\'")}
        end
      end)

    Enum.reduce(prepared_vars, query_string, fn {key, var}, acc ->
      String.replace(acc, "{{#{key}}}", var)
    end)
  end
end
