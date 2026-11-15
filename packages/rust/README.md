# Rust

[![codecov](https://codecov.io/gh/Xynoplex/images/graph/badge.svg?component=rust)](https://app.codecov.io/gh/Xynoplex/images/components)

The first four are the Rust SDK's crates, which live in the [SDK repository](https://github.com/Xynoplex/sdk/tree/main/rust); the services build against them from the SDK artifact bundle. The last three are what the Rust services share, and are built into their binaries. A service's own crates are beside its binary in [images/](../../README.md).

| Crate | Published | Coverage | What it is |
|---|---|---|---|
| [xynoplex](https://github.com/Xynoplex/sdk/tree/main/rust/sdk) | [![crates.io](https://img.shields.io/crates/v/xynoplex.svg)](https://crates.io/crates/xynoplex) | In the SDK repository | The Rust SDK: the client of a knowledge base, the protocol's types, sessions and state units |
| [xynoplex-http-transport](https://github.com/Xynoplex/sdk/tree/main/rust/http-transport) | [![crates.io](https://img.shields.io/crates/v/xynoplex-http-transport.svg)](https://crates.io/crates/xynoplex-http-transport) | In the SDK repository | The SDK's transport over a gateway, and signing a person or a service in |
| [xynoplex-telemetry](https://github.com/Xynoplex/sdk/tree/main/rust/telemetry) | [![crates.io](https://img.shields.io/crates/v/xynoplex-telemetry.svg)](https://crates.io/crates/xynoplex-telemetry) | In the SDK repository | The SDK's spans and counts, reported to whatever OpenTelemetry the application installed. It exports nothing |
| [xynoplex-codegen](https://github.com/Xynoplex/sdk/tree/main/rust/codegen) | [![crates.io](https://img.shields.io/crates/v/xynoplex-codegen.svg)](https://crates.io/crates/xynoplex-codegen) | In the SDK repository | The build-time generator of Rust types from the spec. A build dependency of `xynoplex`: nobody adds it by hand |
| [semiont-core](./core/README.md) | Not published | [![codecov](https://codecov.io/gh/Xynoplex/images/graph/badge.svg?component=rust-core)](https://app.codecov.io/gh/Xynoplex/images/components) | What the Rust services share and no client needs: the embedded spec and its validators, the configuration documents, the reach to the messaging broker |
| [semiont-http-service](./http-service/README.md) | Not published | [![codecov](https://codecov.io/gh/Xynoplex/images/graph/badge.svg?component=rust-http-service)](https://app.codecov.io/gh/Xynoplex/images/components) | What the Rust services that serve HTTP share: connections a service can close from its side, the bearer credential, and the verifier of tokens from the trusted issuer |
| [semiont-observability](./observability/README.md) | Not published | [![codecov](https://codecov.io/gh/Xynoplex/images/graph/badge.svg?component=rust-observability)](https://app.codecov.io/gh/Xynoplex/images/components) | What a Rust service writes about itself: telemetry exported over OTLP, and log lines |

## Where things are

- One Cargo workspace, rooted here: [`Cargo.toml`](./Cargo.toml) names these crates and the Rust images' (`gateway`, `dispatcher`, `archivist`), beside [`Cargo.lock`](./Cargo.lock), cargo-deny's [`deny.toml`](./deny.toml) and the [`rust-toolchain.toml`](./rust-toolchain.toml) every Rust build takes its compiler from. Run `cargo` here; its build output is `target/`.
- CI measures the workspace's coverage twice, and Codecov adds the two under each crate's flag, `rust-<name>`, scoped to the crate's directory. Rust Tests runs the crates' own tests under `cargo llvm-cov`. And the six binaries the conformance suites start (the three services and the SDK's three drivers) are built instrumented: every suite keeps what they ran, and Rust Coverage merges it into one report. The services and the crates only they use, `semiont-core`, `semiont-http-service` and `semiont-observability`, are tested by those suites, and that report is where their tests are counted.

The other languages, and which SDK a program installs, are in [packages/](../README.md).
