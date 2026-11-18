//! The spec a service is built against, embedded when it is compiled: the
//! protocol's OpenAPI document, the Archivist's, and their component schemas
//! as validators, each as make generate bundles them (src/generated/), and the
//! bus registry, with each channel's attributes as the SDK states them
//! (`xynolog::channels::CHANNEL_ATTRIBUTES`).

use jsonschema::{Draft, Validator, ValidatorMap};
use serde_json::Value;
use std::collections::{BTreeSet, HashMap, HashSet};
use std::sync::OnceLock;
use xynolog::channels::{CHANNEL_ATTRIBUTES, ChannelDelivery};

const RELEASE: &str = include_str!("../../../../version.json");
const OPENAPI: &str = include_str!("generated/openapi.json");
const ARCHIVIST_OPENAPI: &str = include_str!("generated/archivist.openapi.json");
const SCHEMAS: &str = include_str!("generated/schemas.json");
const REGISTRY: &str = include_str!("../../../../protocol/specs/src/bus/registry.json");

static VERSION: OnceLock<String> = OnceLock::new();

/// The release this build is: version.json's `version`.
pub fn version() -> &'static str {
    VERSION.get_or_init(|| {
        let release: Value = serde_json::from_str(RELEASE)
            .unwrap_or_else(|e| panic!("the embedded version.json: {e}"));
        release["version"]
            .as_str()
            .unwrap_or_else(|| panic!("the embedded version.json states no version"))
            .to_owned()
    })
}

pub const HTTP_METHODS: [&str; 8] = [
    "get", "put", "post", "delete", "options", "head", "patch", "trace",
];

/// A registry operation: the request, and the channels its reply and failure come on.
#[derive(Debug, Clone)]
pub struct Operation {
    pub result: String,
    pub failure: String,
}

pub struct Spec {
    pub document: Value,
    pub archivist: Value,
    validators: ValidatorMap,
    /// channel → the schema its payload is validated against (`None`: not validated).
    channel_schemas: HashMap<String, Option<String>>,
    operations: HashMap<String, Operation>,
    correlated: HashSet<String>,
    writes: HashSet<String>,
}

static SPEC: OnceLock<Spec> = OnceLock::new();

/// The spec, parsed once. Everything in it is checked by this crate's tests,
/// so a failure here is a build that should not exist.
pub fn spec() -> &'static Spec {
    SPEC.get_or_init(|| Spec::parse().unwrap_or_else(|e| panic!("the embedded spec: {e}")))
}

impl Spec {
    fn parse() -> Result<Spec, String> {
        let document: Value = serde_json::from_str(OPENAPI).map_err(|e| e.to_string())?;
        let archivist: Value =
            serde_json::from_str(ARCHIVIST_OPENAPI).map_err(|e| e.to_string())?;
        let schemas: Value = serde_json::from_str(SCHEMAS).map_err(|e| e.to_string())?;
        let validators = jsonschema::options()
            .with_draft(Draft::Draft7)
            .should_validate_formats(true)
            .build_map(&schemas)
            .map_err(|e| e.to_string())?;

        let registry: Value = serde_json::from_str(REGISTRY).map_err(|e| e.to_string())?;
        let mut channel_schemas = HashMap::new();
        for entry in registry["channels"]
            .as_array()
            .ok_or("the registry lists no channels")?
        {
            let channel = entry["channel"]
                .as_str()
                .ok_or("a registry channel has no name")?;
            channel_schemas.insert(
                channel.to_owned(),
                entry["validate"].as_str().map(str::to_owned),
            );
        }
        let mut operations = HashMap::new();
        for op in registry["operations"]
            .as_array()
            .ok_or("the registry lists no operations")?
        {
            let (Some(request), Some(result), Some(failure)) = (
                op["request"].as_str(),
                op["result"].as_str(),
                op["failure"].as_str(),
            ) else {
                return Err(format!("a registry operation is malformed: {op}"));
            };
            operations.insert(
                request.to_owned(),
                Operation {
                    result: result.to_owned(),
                    failure: failure.to_owned(),
                },
            );
        }

        let correlated = CHANNEL_ATTRIBUTES
            .iter()
            .filter(|(_, attrs)| attrs.delivery == Some(ChannelDelivery::Correlated))
            .map(|(channel, _)| (*channel).to_owned())
            .collect();
        let writes = CHANNEL_ATTRIBUTES
            .iter()
            .filter(|(_, attrs)| attrs.writes == Some(true))
            .map(|(channel, _)| (*channel).to_owned())
            .collect();

        Ok(Spec {
            document,
            archivist,
            validators,
            channel_schemas,
            operations,
            correlated,
            writes,
        })
    }

    /// The validator of a component schema; a name the spec does not declare
    /// is a programming error.
    pub fn validator(&self, schema: &str) -> &Validator {
        self.validators
            .get(&format!("#/definitions/{schema}"))
            .unwrap_or_else(|| panic!("the spec declares no schema {schema}"))
    }

    /// Whether the registry declares `channel`, and if so the schema its payload is held to.
    pub fn channel_schema(&self, channel: &str) -> Option<Option<&str>> {
        self.channel_schemas.get(channel).map(Option::as_deref)
    }

    /// The registry operation `channel` is the request of.
    pub fn operation(&self, channel: &str) -> Option<&Operation> {
        self.operations.get(channel)
    }

    /// A reply channel: delivered only to the client whose request it answers.
    pub fn is_correlated(&self, channel: &str) -> bool {
        self.correlated.contains(channel)
    }

    pub fn correlated_channels(&self) -> Vec<String> {
        let mut channels: Vec<String> = self.correlated.iter().cloned().collect();
        channels.sort();
        channels
    }

    /// Emitting `channel` changes the knowledge base.
    pub fn writes(&self, channel: &str) -> bool {
        self.writes.contains(channel)
    }

    /// Every operation `document` declares, as (method, path).
    pub fn operations_of(document: &Value) -> Vec<(String, String)> {
        let mut out = Vec::new();
        if let Some(paths) = document["paths"].as_object() {
            for (path, item) in paths {
                let Some(item) = item.as_object() else {
                    continue;
                };
                for method in item.keys().filter(|m| HTTP_METHODS.contains(&m.as_str())) {
                    out.push((method.to_uppercase(), path.clone()));
                }
            }
        }
        out
    }
}

/// Every problem `instance` has against `schema`, as one line: what the 400 says.
pub fn problems(schema: &str, instance: &Value) -> Option<String> {
    let validator = spec().validator(schema);
    let lines: Vec<String> = validator
        .iter_errors(instance)
        .map(|error| {
            let path = error.instance_path().to_string();
            let at = if path.is_empty() {
                "root".to_owned()
            } else {
                path
            };
            format!("{at}: {}", error.masked())
        })
        .collect();
    if lines.is_empty() {
        None
    } else {
        Some(lines.join("; "))
    }
}

/// A path's shape, parameter names aside.
fn shape(path: &str) -> String {
    let mut out = String::with_capacity(path.len());
    let mut in_parameter = false;
    for c in path.chars() {
        match c {
            '{' => {
                in_parameter = true;
                out.push_str("{}");
            }
            '}' => in_parameter = false,
            _ if in_parameter => {}
            _ => out.push(c),
        }
    }
    out
}

/// Every difference between the routes a service serves and the operations
/// `document` declares: a route the spec does not declare, or a declared
/// operation nothing serves. A service compares its route table before it
/// listens, and refuses to serve on any difference.
pub fn route_mismatches<'a>(
    document: &Value,
    served: impl IntoIterator<Item = (&'a str, &'a str)>,
) -> Vec<String> {
    let declared: BTreeSet<String> = Spec::operations_of(document)
        .into_iter()
        .map(|(m, p)| format!("{m} {}", shape(&p)))
        .collect();
    let served: BTreeSet<String> = served
        .into_iter()
        .map(|(m, p)| format!("{m} {}", shape(p)))
        .collect();
    let mut problems: Vec<String> = served
        .difference(&declared)
        .map(|op| format!("{op} is served, and the spec does not declare it"))
        .collect();
    problems.extend(
        declared
            .difference(&served)
            .map(|op| format!("{op} is declared, and nothing serves it")),
    );
    problems
}

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::json;

    // Every component schema compiles on its own, with every schema a $ref
    // from it follows: one that cannot fails here, never at boot or on a
    // request.
    #[test]
    fn every_component_schema_compiles() {
        let definitions: Value = serde_json::from_str(SCHEMAS).expect("schemas.json is JSON");
        let names: Vec<&String> = definitions["definitions"]
            .as_object()
            .expect("schemas.json has definitions")
            .keys()
            .collect();
        assert!(!names.is_empty(), "the spec declares no component schemas");
        for name in names {
            let mut schema = definitions.clone();
            schema["$ref"] = json!(format!("#/definitions/{name}"));
            if let Err(error) = jsonschema::options()
                .with_draft(Draft::Draft7)
                .should_validate_formats(true)
                .build(&schema)
            {
                panic!(
                    "the spec's schema {name} does not compile (a $ref it follows may be at fault): {error}"
                );
            }
        }
    }

    #[test]
    fn the_bus_registry_declares_operations() {
        assert!(
            !spec().operations.is_empty(),
            "the bus registry declares no operations"
        );
    }

    #[test]
    fn every_channel_is_validated_against_a_schema_the_spec_declares() {
        let spec = spec();
        for (channel, schema) in &spec.channel_schemas {
            if let Some(schema) = schema {
                assert!(
                    spec.validators
                        .get(&format!("#/definitions/{schema}"))
                        .is_some(),
                    "the bus registry validates {channel} against {schema}, which the spec does not declare"
                );
            }
        }
    }
}
