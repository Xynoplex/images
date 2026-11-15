"""The vector index Xynolog's Python services write and search, and the embedding providers that make its vectors.

Every name is imported from the module that has it, and from nowhere else:
what an index is asked and answers (`xynolog_vectors.store`); what a point of
it is (`xynolog_vectors.payload`); folding the chunks a search found to one
entry for each resource (`xynolog_vectors.merge`); and what an embedding
provider is asked and answers, with the failure one raises
(`xynolog_vectors.embedding`).

A store is a module too: `xynolog_vectors.qdrant`, which asks a Qdrant over
its HTTP API and has the reader of one beside the store, and
`xynolog_vectors.memory`, which holds its index in the process, for tests.
So is a provider: `xynolog_vectors.ollama`,
`xynolog_vectors.voyage`, and `xynolog_vectors.mock`, which asks nobody and
answers a vector worked out from the text, for tests. A service makes the
store and the provider its configuration document names with
`xynolog_vectors.factory`. Importing this package imports none of them.
"""
