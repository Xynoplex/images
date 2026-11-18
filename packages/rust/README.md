# Rust

The first four are the Rust SDK's crates, which live in the [SDK repository](https://github.com/xynolog/sdk/tree/main/rust); the services build against them from the SDK artifact bundle. The last three are what the Rust services share, and are built into their binaries. A service's own crates are beside its binary in [images/](../../README.md).

| Crate | Published | What it is |
|---|---|---|
| [xynolog](https://github.com/xynolog/sdk/tree/main/rust/sdk) | [![crates.io](https://img.shields.io/crates/v/xynolog.svg)](https://crates.io/crates/xynolog) | The Rust SDK: the client of a knowledge base, the protocol's types, sessions and state units |
| [xynolog-http-transport](https://github.com/xynolog/sdk/tree/main/rust/http-transport) | [![crates.io](https://img.shields.io/crates/v/xynolog-http-transport.svg)](https://crates.io/crates/xynolog-http-transport) | The SDK's transport over a gateway, and signing a person or a service in |
| [xynolog-telemetry](https://github.com/xynolog/sdk/tree/main/rust/telemetry) | [![crates.io](https://img.shields.io/crates/v/xynolog-telemetry.svg)](https://crates.io/crates/xynolog-telemetry) | The SDK's spans and counts, reported to whatever OpenTelemetry the application installed. It exports nothing |
| [xynolog-codegen](https://github.com/xynolog/sdk/tree/93a6c5fb1fc1cd7e6792dfa84a88921ea79c0208/rust/codegen) | [![crates.io](https://img.shields.io/crates/v/xynolog-codegen.svg)](https://crates.io/crates/xynolog-codegen) | The build-time generator of Rust types from the spec. A build dependency of `xynolog`: nobody adds it by hand |
| [xynolog-core](./core/README.md) | Not published | What the Rust services share and no client needs: the embedded spec and its validators, the configuration documents, the reach to the messaging broker |
| [xynolog-http-service](./http-service/README.md) | Not published | What the Rust services that serve HTTP share: connections a service can close from its side, the bearer credential, and the verifier of tokens from the trusted issuer |
| [xynolog-observability](./observability/README.md) | Not published | What a Rust service writes about itself: telemetry exported over OTLP, and log lines |

## Where things are

- One Cargo workspace, rooted here: [`Cargo.toml`](./Cargo.toml) names these crates and the Rust images' (`gateway`, `dispatcher`, `archivist`), beside [`Cargo.lock`](./Cargo.lock), cargo-deny's [`deny.toml`](./deny.toml) and the [`rust-toolchain.toml`](./rust-toolchain.toml) every Rust build takes its compiler from. Run `cargo` here; its build output is `target/`.
- `cargo test --workspace` here runs every crate's tests. The three services, and the crates only they use (`xynolog-core`, `xynolog-http-service` and `xynolog-observability`), are also held to the protocol by its [conformance suites](https://github.com/xynolog/protocol/blob/main/conformance/README.md), which run against the built binaries.

The other languages, and which SDK a program installs, are in the [SDK repository](https://github.com/xynolog/sdk/blob/main/README.md).
