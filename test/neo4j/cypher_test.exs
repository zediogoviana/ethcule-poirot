defmodule Neo4j.CypherTest do
  use ExUnit.Case
  doctest Neo4j.Cypher

  alias Neo4j.Cypher

  describe "prepared_statement/2" do
    test "it creates a valid prepared statement" do
      query = "MATCH ({{label}}) -[{{relation}}] -> () DELETE {{label}}, {{relation}}"
      parameters = [label: "Address", relation: "Sent"]

      prepared_query = Cypher.prepared_statement(query, parameters)

      assert prepared_query == "MATCH (Address) -[Sent] -> () DELETE Address, Sent"
    end

    test "it escapes parameters and returns a prepared statement" do
      # Check here for an example of Label Injection
      # https://neo4j.com/developer/kb/protecting-against-cypher-injection/
      # This prepared statement handles the parameter as expected
      query = "CREATE (s:Student) SET s.name = '{{student_name}}'"

      parameters = [
        student_name: "Robby' WITH DISTINCT true as haxxored MATCH (s:Student) DETACH DELETE s //"
      ]

      prepared_query = Cypher.prepared_statement(query, parameters)

      assert prepared_query ==
               "CREATE (s:Student) SET s.name = 'Robby\\' WITH DISTINCT true as haxxored MATCH (s:Student) DETACH DELETE s //'"
    end
  end
end
