//! The types of the schemas only the services read — their configuration
//! documents, and what a service keeps or answers of its own — as make
//! generate writes them from the spec and service-schemas.json. A protocol
//! schema they reach is the SDK's type (`xynolog::types`).

use xynolog::schema;

include!("generated/service_types.rs");
