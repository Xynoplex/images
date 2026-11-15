# semiont-core

[![codecov](https://codecov.io/gh/Xynoplex/images/graph/badge.svg?component=rust-core)](https://app.codecov.io/gh/Xynoplex/images/components)

What Semiont's Rust services share and no client needs.

**Not published.** It is a crate of this workspace, built into the
[gateway](../../../gateway/README.md) and the
[dispatcher](../../../dispatcher/README.md). To use Xynoplex from Rust, the
crate you want is [`xynoplex`](https://github.com/Xynoplex/sdk/tree/main/rust/sdk).

| Module | What it holds |
|---|---|
| `spec` | The spec each service is built against, embedded and checked when it compiles: validators for every component schema, the bus registry and its classification, and the route-table comparison. |
| `types`, `config` | The service-only types generated from the spec (the configuration documents, the job record), and reading a configuration document from `--config`, validated before it is used. |
| `nats` (feature `nats`) | Reaching the messaging broker. Only a crate that implements a broker-backed interface enables it, and CI holds the crates that must not. |

It is separate from the SDK so that a client links none of this: no
validators, no configuration reader, no broker.

A protocol type it reaches is the SDK's (`xynoplex::types`): one home for
each. What a service writes about itself is
[`semiont-observability`](../observability/README.md)'s, and how it
reaches the bus is the SDK's client over
[`xynoplex-http-transport`](https://github.com/Xynoplex/sdk/tree/main/rust/http-transport).
