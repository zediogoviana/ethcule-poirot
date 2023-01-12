# Some Cypher Queries you can run in your Neo4j Server

1. Detecting Cycles between all nodes 

```cypher
MATCH
  (m1)-[t:TO {status: "OK"}]->(m2),
  cyclePath=shortestPath((m2)-[:TO*..20]->(m1))
WHERE m1 <> m2 
WITH
  m1, nodes(cyclePath) as cycle
WHERE id(m1) = apoc.coll.max([node in cycle | id(node)]) 
RETURN m1, cycle
```

2. All Paths from one Wallet to another

```cypher
MATCH p=({eth_address:"0x1234"})-[r*..4 {status: "OK"}]->({eth_address:"0x9876"})
WHERE all(x IN relationships(p) WHERE toFloat(x.eth_value) > 0)
RETURN p
```

3. Shortest Path between 1 node all other nodes

```cypher
MATCH (a1:Account { eth_address: '0x1234' }), path = shortestPath((a1)-[*..15]->(a2)) 
WHERE a1 <> a2 and all(x IN relationships(path) WHERE x.status = "OK")
RETURN path
```

4. Shortest Path between 2 nodes (using an `ENS` name instead of the address)

```cypher
MATCH (a1:Account { eth_address: '0x1234' }),(a2:Account { ens_name: "ens_name.eth" }), path = shortestPath((a1)-[*..15]->(a2)) 
RETURN path
```
