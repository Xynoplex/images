//! What Xynolog's Rust services share and no client needs: the spec each is
//! built against, the configuration document each reads at boot, and their
//! reach to the messaging broker. A client's share is public: the protocol's
//! types and the bus client (`xynolog`), its transport over HTTP
//! (`xynolog-http-transport`), and its telemetry and logging
//! (`xynolog-observability`).

#![forbid(unsafe_code)]

pub mod config;
#[cfg(feature = "nats")]
pub mod nats;
pub mod spec;
pub mod types;
