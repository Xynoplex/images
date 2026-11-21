// Generated from the schemas in protocol/specs/src and packages/rust/core/service-schemas.json; do not edit.
// Regenerate: make generate (xynolog/sdk's codegen/lib/images/service_types.ml)
/// The knowledge base's entity-type vocabulary: the file `projections/__system__/entitytypes.json` under the state directory, the sum of the `frame:entity-type-added` events. Written as JSON indented by two spaces.
#[derive(Debug, Clone, PartialEq, serde::Deserialize, serde::Serialize)]
#[serde(deny_unknown_fields)]
pub struct EntityTypesProjection {
    /// Every entity type added, each once, sorted.
    #[serde(rename = "entityTypes")]
    pub entity_types: Vec<String>,
}

schema!(EntityTypesProjection);

/// One job as the queue stores it: the job, and when it last showed life. The dead-worker sweep reads `lastProgressAt`: a running job whose worker has reported nothing for the configured interval is presumed dead. Where the queue keeps these records is the job storage layout, specs/src/jobs/storage.json.
#[derive(Debug, Clone, PartialEq, serde::Deserialize, serde::Serialize)]
#[serde(deny_unknown_fields)]
pub struct JobRecord {
    pub job: xynolog::types::Job,
    /// When the job was created, claimed, checkpointed or last reported progress, as an ISO 8601 timestamp.
    #[serde(rename = "lastProgressAt")]
    pub last_progress_at: String,
}

schema!(JobRecord);

/// What the principals of a knowledge base are called: the file `projections/__system__/profiles.json` under the state directory, the sum of the `principal:profiled` events. The Archivist writes it; the Archivist and the Librarian read it to name the principals a reply mentions. Written as JSON indented by two spaces.
#[derive(Debug, Clone, PartialEq, serde::Deserialize, serde::Serialize)]
#[serde(deny_unknown_fields)]
pub struct ProfilesProjection {
    /// Each principal's current profile, keyed by its DID.
    pub profiles: std::collections::BTreeMap<String, xynolog::types::Profile>,
}

schema!(ProfilesProjection);

/// The annotations on one resource, as its materialized view holds them.
#[derive(Debug, Clone, PartialEq, serde::Deserialize, serde::Serialize)]
#[serde(deny_unknown_fields)]
pub struct ResourceAnnotations {
    #[serde(rename = "resourceId")]
    pub resource_id: xynolog::types::ResourceId,
    /// Each annotation as the `mark:added` event that recorded it carried it, with the body changes recorded since applied. In the order they were first recorded.
    pub annotations: Vec<xynolog::types::Annotation>,
    /// How many of the resource's events the view has applied.
    pub version: u64,
    /// The timestamp of the last event applied; the empty string before any.
    #[serde(rename = "updatedAt")]
    pub updated_at: String,
}

schema!(ResourceAnnotations);

/// A resource's materialized view: the file the Archivist writes at `resources/<ab>/<cd>/<resourceId>.json` under the knowledge base's state directory, and every reader of that file reads. It is what the resource's events add up to, and is rebuilt from the event log whenever it is missing. Written as JSON indented by two spaces, by writing a sibling temporary file and renaming it onto the path, so a reader sees a whole document or none.
#[derive(Debug, Clone, PartialEq, serde::Deserialize, serde::Serialize)]
#[serde(deny_unknown_fields)]
pub struct ResourceView {
    pub resource: xynolog::types::ResourceDescriptor,
    pub annotations: ResourceAnnotations,
    /// The sequence number of the last event applied. A graph read that follows a write waits for the graph projection to reach it.
    #[serde(rename = "lastSequence")]
    pub last_sequence: u64,
}

schema!(ResourceView);

/// One entry of the storage-uri index: the file `projections/storage-uri/<ab>/<cd>/<sha256 of the URI, hex>.json` under the state directory. It answers which resource's content is at a place in the working tree. Written as JSON indented by two spaces, `uri` first.
#[derive(Debug, Clone, PartialEq, serde::Deserialize, serde::Serialize)]
#[serde(deny_unknown_fields)]
pub struct StorageUriEntry {
    /// The `file://` URI of a place in the working tree, relative to the knowledge base's root.
    pub uri: String,
    #[serde(rename = "resourceId")]
    pub resource_id: xynolog::types::ResourceId,
}

schema!(StorageUriEntry);

/// The knowledge base's tag schemas: the file `projections/__system__/tagschemas.json` under the state directory, the sum of the `frame:tag-schema-added` events. Written as JSON indented by two spaces.
#[derive(Debug, Clone, PartialEq, serde::Deserialize, serde::Serialize)]
#[serde(deny_unknown_fields)]
pub struct TagSchemasProjection {
    /// Every tag schema added, sorted by `id`. A schema added again under an `id` replaces the one held.
    #[serde(rename = "tagSchemas")]
    pub tag_schemas: Vec<xynolog::types::TagSchema>,
}

schema!(TagSchemasProjection);
