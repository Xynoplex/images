"""The graph databases Xynolog's Python services write and read, behind one interface.

Every name is imported from the module that has it, and from nowhere else:
what a graph database is asked and answers (`xynolog_graph.interface`); how a
resource and an annotation become stored properties and back, and what the
graph is meant to hold of each (`xynolog_graph.codec`); and making a store
or a reader from what a configuration names (`xynolog_graph.factory`).

A store is a module too: `xynolog_graph.neo4j`, `xynolog_graph.janusgraph`,
`xynolog_graph.neptune`, and `xynolog_graph.memory`, which holds its graph in
the process, for tests. Importing this package imports none of them, so it
imports no database's client: a store that asks its database through a client
comes with an extra of this package, and only whoever asks for that store
needs it.
"""
