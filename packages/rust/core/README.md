# xynolog-core

[![codecov](https://codecov.io/gh/xynolog/images/graph/badge.svg?component=rust-core)](https://app.codecov.io/gh/xynolog/images/components)

What Xynolog's Rust services share and no client needs.

**Not published.** It is a crate of this workspace, built into the
[gateway](../../../gateway/README.md) and the
[dispatcher](../../../dispatcher/README.md). To use Xynolog from Rust, the
crate you want is [`xynolog`](https://github.com/xynolog/sdk/tree/main/rust/sdk).

| Module | What it holds |
|---|---|
| `spec` | The spec each service is built against, embedded when it compiles (`src/generated/`, which `make generate` writes): validators for every component schema, the bus registry with each channel's attributes as the SDK states them, and the route-table comparison. |
| `types`, `config` | The service-only types generated from the spec (the configuration documents, the job record), and reading a configuration document from `--config`, validated before it is used. |
| `nats` (feature `nats`) | Reaching the messaging broker. Only a crate that implements a broker-backed interface enables it, and CI holds the crates that must not. |

It is separate from the SDK so that a client links none of this: no
validators, no configuration reader, no broker.

A protocol type it reaches is the SDK's (`xynolog::types`): one home for
each. What a service writes about itself is
[`xynolog-observability`](../observability/README.md)'s, and how it
reaches the bus is the SDK's client over
[`xynolog-http-transport`](https://github.com/xynolog/sdk/tree/main/rust/http-transport).
