"""The model providers Xynolog's Python services call, behind one interface.

Every name is imported from the module that has it, and from nowhere else:
what a client is, what it answers and how it fails
(`xynolog_inference.interface`); making a client from what a knowledge base's
config names (`xynolog_inference.factory`); what a service that holds clients
reports of its models' limits (`xynolog_inference.limits_report`); and what a
model catalogue file says of a model whose provider does not say it itself,
read from the path it is given (`xynolog_inference.catalogue`).

A driver is a module too: `xynolog_inference.anthropic`,
`xynolog_inference.google`, `xynolog_inference.llamacpp`,
`xynolog_inference.ollama`, `xynolog_inference.openai`,
`xynolog_inference.together`, `xynolog_inference.vllm`, and
`xynolog_inference.mock`, which answers from a list, for tests. Importing
this package imports none of them, so it imports no provider's library: a
driver that asks its provider through a library comes with an extra of this
package, and only whoever asks for that driver needs it.
"""
