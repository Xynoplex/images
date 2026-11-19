// Generated from the component schemas in protocol/specs/src and packages/rust/core/service-schemas.json; do not edit.
// Regenerate: make generate (xynolog/sdk's codegen/lib/images/service_types.ml)
/// The bytes were declined: no text is extracted from them.
#[derive(Debug, Clone, PartialEq, serde::Deserialize, serde::Serialize)]
#[serde(deny_unknown_fields)]
pub struct AnchoredTextDeclinedEntry {
    /// The entry format.
    pub v: i64,
    /// The stamp the entry was derived under: the PDF reader's and the OCR engine's. A reader takes the entry only when it equals the stamp the Smelter last stated.
    pub stamp: String,
    /// Why extraction yielded nothing, by class.
    pub declined: xynolog::types::ExtractionDeclinedReason,
}

schema!(AnchoredTextDeclinedEntry);

/// One entry of the anchored-text store: the file `<ab>/<cd>/<key>.json` under the store's directory, where the key is the SHA-256 of the bytes the text was extracted from, in hex. The Smelter derives it and stores it over the Archivist's HTTP surface (`AnchoredTextWrite`); the Archivist writes it, as compact JSON with `v` and `stamp` first, to a sibling temporary file renamed onto the path. The stamp the Smelter states (`AnchoredTextStamp`) is kept, followed by a newline, in the file `STAMP` at the store's root.
#[derive(Debug, Clone, PartialEq, serde::Deserialize, serde::Serialize)]
#[serde(untagged)]
pub enum AnchoredTextEntry {
    ExtractedEntry(AnchoredTextExtractedEntry),
    DeclinedEntry(AnchoredTextDeclinedEntry),
}

member!(AnchoredTextEntry::ExtractedEntry(
    AnchoredTextExtractedEntry,
));
member!(AnchoredTextEntry::DeclinedEntry(AnchoredTextDeclinedEntry));
schema!(AnchoredTextEntry);

/// The text extracted from the bytes, where each word is on the page, and how it was extracted.
#[derive(Debug, Clone, PartialEq, serde::Deserialize, serde::Serialize)]
#[serde(deny_unknown_fields)]
pub struct AnchoredTextExtractedEntry {
    /// The entry format.
    pub v: i64,
    /// The stamp the entry was derived under: the PDF reader's and the OCR engine's. A reader takes the entry only when it equals the stamp the Smelter last stated.
    pub stamp: String,
    /// The extracted text.
    pub text: String,
    /// Where each word of `text` is, line by line, in reading order.
    pub lines: Vec<AnchoredTextExtractedEntryLinesItem>,
    /// How the text was extracted.
    pub method: xynolog::types::ExtractionMethod,
    /// PDF classification, when the source was a PDF.
    #[serde(rename = "pdfClass")]
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub pdf_class: Option<xynolog::types::PdfClass>,
    /// How well the engine read the pixels, when any of this text came from OCR.
    #[serde(rename = "ocrConfidence")]
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub ocr_confidence: Option<xynolog::types::OcrConfidence>,
    /// 1-indexed pages this extraction could not read — present only for partially covered documents (class C).
    #[serde(rename = "unreadPages")]
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub unread_pages: Option<Vec<i64>>,
}

impl AnchoredTextExtractedEntry {
    /// The `AnchoredTextExtractedEntry` that states these and nothing else.
    pub fn new(
        v: i64,
        stamp: impl Into<String>,
        text: impl Into<String>,
        lines: Vec<AnchoredTextExtractedEntryLinesItem>,
        method: xynolog::types::ExtractionMethod,
    ) -> Self {
        Self {
            v,
            stamp: stamp.into(),
            text: text.into(),
            lines,
            method,
            pdf_class: None,
            ocr_confidence: None,
            unread_pages: None,
        }
    }
}

schema!(AnchoredTextExtractedEntry);

/// One line of text: the words that share a page, a baseline and a height.
#[derive(Debug, Clone, PartialEq, serde::Deserialize, serde::Serialize)]
#[serde(deny_unknown_fields)]
pub struct AnchoredTextExtractedEntryLinesItem {
    /// The page, counted from 1.
    pub p: i64,
    /// The line's vertical position in PDF points, from the bottom of the page.
    pub y: f64,
    /// The line's height in PDF points.
    pub h: f64,
    /// Each word as `[x, width, start, end]`: its horizontal position and width in PDF points, and the offsets of its text in `text`, which are whole numbers of Unicode code points from the start of `text`.
    pub words: Vec<Vec<f64>>,
}

/// Everything the Archivist reads at boot: nothing in it is defaulted by the Archivist. The launcher writes it for the Archivist it starts, from the knowledge base's stack documents, and the Archivist reads it from the path its `--config` flag names (its image passes `/etc/xynolog/archivist.json`). Started without `--config`, or with a path that names no file, the Archivist refuses to start and says which. No secret is a value here. What the knowledge base says of itself is not here either: its name, its `site.domain` and its `git.sync` are read from the committed `.xynolog/config.yaml` of the tree at `root`. The Archivist's other inputs are the environment variables specs/src/service-environment/variables.json lists for it. A document that does not validate is refused at boot, naming each failing field.
#[derive(Debug, Clone, PartialEq, serde::Deserialize, serde::Serialize)]
#[serde(deny_unknown_fields)]
pub struct ArchivistConfig {
    /// The URL the Archivist reaches the gateway at: its only route to the bus.
    #[serde(rename = "gatewayUrl")]
    pub gateway_url: String,
    /// The issuer the Archivist's service account signs in at, and whose tokens it admits callers of its HTTP surface by.
    pub identity: ServiceIdentity,
    /// The knowledge base's working tree: the directory holding `.xynolog/`. The event log, the content and the committed config are under it.
    pub root: String,
    /// The state volume, this knowledge base's alone: the Archivist keeps the knowledge base's views and projections in it, at its top.
    #[serde(rename = "stateHome")]
    pub state_home: String,
    /// The anchored-text store, which only the Archivist mounts: the Smelter stores each entry in it over HTTP, and the Archivist serves it.
    #[serde(rename = "anchoredTextDir")]
    pub anchored_text_dir: String,
    pub engines: ArchivistEngines,
    /// The port the Archivist's HTTP surface answers on, `/health` included.
    pub port: u16,
    /// Whether the Archivist serves the views it finds at boot instead of rebuilding them from the event log first.
    #[serde(rename = "skipRebuild")]
    pub skip_rebuild: bool,
    /// The bounds on how far the staging driver may run behind the working tree, in milliseconds. A knowledge base that does not sync git stages nothing, and reads neither.
    pub staging: ArchivistConfigStaging,
    #[serde(rename = "logLevel")]
    pub log_level: xynolog::types::LogLevel,
    #[serde(rename = "logFormat")]
    pub log_format: xynolog::types::LogFormat,
}

schema!(ArchivistConfig);

/// The bounds on how far the staging driver may run behind the working tree, in milliseconds. A knowledge base that does not sync git stages nothing, and reads neither.
#[derive(Debug, Clone, PartialEq, serde::Deserialize, serde::Serialize)]
#[serde(deny_unknown_fields)]
pub struct ArchivistConfigStaging {
    /// The quiet period after the last change before pending changes are staged.
    #[serde(rename = "flushMs")]
    pub flush_ms: u64,
    /// The longest a change waits to be staged while others keep arriving, measured from the oldest pending change.
    #[serde(rename = "maxWaitMs")]
    pub max_wait_ms: u64,
}

/// The engine for each job and each Librarian actor, behind `browse:engines`: a provider and a model, and no credential. It is the knowledge base's Inference document's `engines` as they stand, with no fallback, so a job or an actor absent here has no engine.
#[derive(Debug, Clone, PartialEq, serde::Deserialize, serde::Serialize)]
#[serde(deny_unknown_fields)]
pub struct ArchivistEngines {
    /// The engine each job is done with when software does it, keyed as a job description is: by `jobType`, and for `mark` by motivation.
    pub jobs: ArchivistEnginesJobs,
    /// The engine each Librarian actor that calls a model asks.
    pub actors: ArchivistEnginesActors,
}

schema!(ArchivistEngines);

/// The engine each Librarian actor that calls a model asks.
#[derive(Debug, Clone, PartialEq, serde::Deserialize, serde::Serialize)]
#[serde(deny_unknown_fields)]
pub struct ArchivistEnginesActors {
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub gatherer: Option<xynolog::types::Engine>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub matcher: Option<xynolog::types::Engine>,
}

/// The engine each job is done with when software does it, keyed as a job description is: by `jobType`, and for `mark` by motivation.
#[derive(Debug, Clone, PartialEq, serde::Deserialize, serde::Serialize)]
#[serde(deny_unknown_fields)]
pub struct ArchivistEnginesJobs {
    /// The engine for `mark` jobs of each motivation.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub mark: Option<ArchivistEnginesJobsMark>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub r#yield: Option<xynolog::types::Engine>,
}

/// The engine for `mark` jobs of each motivation.
#[derive(Debug, Clone, PartialEq, serde::Deserialize, serde::Serialize)]
#[serde(deny_unknown_fields)]
pub struct ArchivistEnginesJobsMark {
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub highlighting: Option<xynolog::types::Engine>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub commenting: Option<xynolog::types::Engine>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub assessing: Option<xynolog::types::Engine>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub linking: Option<xynolog::types::Engine>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub tagging: Option<xynolog::types::Engine>,
}

/// The Archivist's liveness answer: it serves, and the actors it hosts.
#[derive(Debug, Clone, PartialEq, serde::Deserialize, serde::Serialize)]
pub struct ArchivistHealth {
    pub status: ArchivistHealthStatus,
    /// The record actors this process hosts.
    pub actors: Vec<String>,
}

impl ArchivistHealth {
    /// The `ArchivistHealth` that states these and nothing else.
    pub fn new(actors: Vec<String>) -> Self {
        Self {
            status: ArchivistHealthStatus::Ok,
            actors,
        }
    }
}

schema!(ArchivistHealth);

#[derive(
    Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Hash, serde::Deserialize, serde::Serialize,
)]
pub enum ArchivistHealthStatus {
    #[serde(rename = "ok")]
    Ok,
}

impl ArchivistHealthStatus {
    /// The value as the wire spells it.
    pub const fn as_str(&self) -> &'static str {
        match self {
            ArchivistHealthStatus::Ok => "ok",
        }
    }
}

/// Everything the dispatcher reads at boot: nothing in it is defaulted by the dispatcher. The launcher writes it for the dispatcher it starts, from the knowledge base's stack documents, and the dispatcher reads it from the path its `--config` flag names (its image passes `/etc/xynolog/dispatcher.json`). Started without `--config`, or with a path that names no file, the dispatcher refuses to start and says which. Secrets are never values here: a field that needs one names the environment variable holding it. The dispatcher's other inputs are the environment variables specs/src/service-environment/variables.json lists for it, and the ones this document names. A document that does not validate is refused at boot, naming each failing field.
#[derive(Debug, Clone, PartialEq, serde::Deserialize, serde::Serialize)]
#[serde(deny_unknown_fields)]
pub struct DispatcherConfig {
    pub kb: KbIdentity,
    /// The URL the dispatcher reaches the gateway at: its only route to the bus.
    #[serde(rename = "gatewayUrl")]
    pub gateway_url: String,
    /// The issuer the dispatcher's service account signs in at.
    pub identity: ServiceIdentity,
    /// The JetStream broker holding the job queue, whose layout is specs/src/jobs/storage.json.
    pub queue: DispatcherConfigQueue,
    /// The port the dispatcher answers `/health` on.
    pub port: u16,
    /// The queue's clocks, in milliseconds. The launcher writes the values a deployment runs with; a test harness shrinks them.
    pub timing: DispatcherConfigTiming,
    #[serde(rename = "logLevel")]
    pub log_level: xynolog::types::LogLevel,
    #[serde(rename = "logFormat")]
    pub log_format: xynolog::types::LogFormat,
}

schema!(DispatcherConfig);

/// The JetStream broker holding the job queue, whose layout is specs/src/jobs/storage.json.
#[derive(Debug, Clone, PartialEq, serde::Deserialize, serde::Serialize)]
#[serde(deny_unknown_fields)]
pub struct DispatcherConfigQueue {
    /// The broker's address (`host:port`, or several, comma-separated).
    pub servers: String,
    /// The environment variable holding the broker user, when the broker requires one.
    #[serde(rename = "userEnv")]
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub user_env: Option<String>,
    /// The environment variable holding the broker password, when the broker requires one.
    #[serde(rename = "passwordEnv")]
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub password_env: Option<String>,
}

impl DispatcherConfigQueue {
    /// The `DispatcherConfigQueue` that states these and nothing else.
    pub fn new(servers: impl Into<String>) -> Self {
        Self {
            servers: servers.into(),
            user_env: None,
            password_env: None,
        }
    }
}

/// The queue's clocks, in milliseconds. The launcher writes the values a deployment runs with; a test harness shrinks them.
#[derive(Debug, Clone, PartialEq, serde::Deserialize, serde::Serialize)]
#[serde(deny_unknown_fields)]
pub struct DispatcherConfigTiming {
    /// How often the queue re-announces pending jobs and sweeps for dead workers. The re-announcement is insurance against a lost wake-up, not dispatch.
    #[serde(rename = "tickMs")]
    pub tick_ms: u64,
    /// How long a running job may go without progress, a checkpoint or a claim before its worker is presumed dead.
    #[serde(rename = "staleRunningMs")]
    pub stale_running_ms: u64,
    /// How long the broker waits, after this dispatcher stops renewing a job's lease, before redelivering its message.
    #[serde(rename = "ackWaitMs")]
    pub ack_wait_ms: u64,
    /// How long a concluded job is kept before it is deleted.
    #[serde(rename = "retentionMs")]
    pub retention_ms: u64,
    /// How often concluded jobs past `retentionMs` are deleted.
    #[serde(rename = "retentionSweepMs")]
    pub retention_sweep_ms: u64,
    /// The least time between two progress writes for one job; reports closer together than this are not written.
    #[serde(rename = "progressWriteIntervalMs")]
    pub progress_write_interval_ms: u64,
    /// How long the dispatcher waits at boot for the broker before it exits, so that a restart policy can retry.
    #[serde(rename = "bootDeadlineMs")]
    pub boot_deadline_ms: u64,
}

/// The dispatcher's liveness answer. It answers only once its queue has connected and its bus pumps are attached, so a 200 means it can take work.
#[derive(Debug, Clone, PartialEq, serde::Deserialize, serde::Serialize)]
#[serde(deny_unknown_fields)]
pub struct DispatcherHealth {
    pub status: DispatcherHealthStatus,
    /// The queue it holds.
    pub queue: DispatcherHealthQueue,
}

impl Default for DispatcherHealth {
    fn default() -> Self {
        Self::new()
    }
}

impl DispatcherHealth {
    /// The `DispatcherHealth` that states what it must and nothing else.
    pub fn new() -> Self {
        Self {
            status: DispatcherHealthStatus::Ok,
            queue: DispatcherHealthQueue::Jetstream,
        }
    }
}

schema!(DispatcherHealth);

/// The queue it holds.
#[derive(
    Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Hash, serde::Deserialize, serde::Serialize,
)]
pub enum DispatcherHealthQueue {
    #[serde(rename = "jetstream")]
    Jetstream,
}

impl DispatcherHealthQueue {
    /// The value as the wire spells it.
    pub const fn as_str(&self) -> &'static str {
        match self {
            DispatcherHealthQueue::Jetstream => "jetstream",
        }
    }
}

#[derive(
    Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Hash, serde::Deserialize, serde::Serialize,
)]
pub enum DispatcherHealthStatus {
    #[serde(rename = "ok")]
    Ok,
}

impl DispatcherHealthStatus {
    /// The value as the wire spells it.
    pub const fn as_str(&self) -> &'static str {
        match self {
            DispatcherHealthStatus::Ok => "ok",
        }
    }
}

/// The knowledge base's entity-type vocabulary: the file `projections/__system__/entitytypes.json` under the state directory, the sum of the `frame:entity-type-added` events. Written as JSON indented by two spaces.
#[derive(Debug, Clone, PartialEq, serde::Deserialize, serde::Serialize)]
#[serde(deny_unknown_fields)]
pub struct EntityTypesProjection {
    /// Every entity type added, each once, sorted.
    #[serde(rename = "entityTypes")]
    pub entity_types: Vec<String>,
}

schema!(EntityTypesProjection);

/// Everything the gateway reads at boot: nothing in it is defaulted by the gateway. The launcher writes it for the gateway it starts — from the knowledge base's committed identity and its stack documents — and a gateway started any other way is given the same document at the path its `--config` flag names (the image passes `/etc/xynolog/gateway.json`). Started without `--config`, or with a path that names no file, the gateway refuses to start and says which. Secrets are never values here: a field that needs one names the environment variable holding it. The gateway's other inputs are the environment variables specs/src/service-environment/variables.json lists for it, and the ones this document names. A document that does not validate is refused at boot — the gateway exits without serving — and the refusal names each failing field by its JSON pointer.
#[derive(Debug, Clone, PartialEq, serde::Deserialize, serde::Serialize)]
#[serde(deny_unknown_fields)]
pub struct GatewayConfig {
    pub kb: KbIdentity,
    /// The port the gateway listens on, on every address the host has: IPv4 and IPv6.
    pub port: u16,
    /// The URL clients reach this gateway at: the `servers` entry of the OpenAPI document it serves.
    #[serde(rename = "publicUrl")]
    pub public_url: String,
    /// The issuer this knowledge base trusts.
    pub identity: GatewayConfigIdentity,
    /// Where the Archivist listens.
    pub archivist: ServiceAddress,
    /// The signal plane: `in-process`, one gateway on its own fabric; or `nats`, the fabric every replica on one broker shares, which requires `servers` and a broker with JetStream.
    pub signal: GatewayConfigSignal,
    #[serde(rename = "logLevel")]
    pub log_level: xynolog::types::LogLevel,
    #[serde(rename = "logFormat")]
    pub log_format: xynolog::types::LogFormat,
    /// What this gateway process can hold, from the memory its deployment gives it. `queuedBytes`: the bytes queued for all its streams together; at it, a new stream is refused with 503 (`AtCapacity`, code `capacity`) until the queues drain — each stream's own bound is `x-xynolog-limits.pendingWriteBytes`. `connections`: the connections it holds open at once; one past it is closed unanswered. The launcher derives both from the memory it gives the gateway's container.
    pub capacity: GatewayConfigCapacity,
}

schema!(GatewayConfig);

/// What this gateway process can hold, from the memory its deployment gives it. `queuedBytes`: the bytes queued for all its streams together; at it, a new stream is refused with 503 (`AtCapacity`, code `capacity`) until the queues drain — each stream's own bound is `x-xynolog-limits.pendingWriteBytes`. `connections`: the connections it holds open at once; one past it is closed unanswered. The launcher derives both from the memory it gives the gateway's container.
#[derive(Debug, Clone, PartialEq, serde::Deserialize, serde::Serialize)]
#[serde(deny_unknown_fields)]
pub struct GatewayConfigCapacity {
    #[serde(rename = "queuedBytes")]
    pub queued_bytes: u64,
    pub connections: u64,
}

/// The issuer this knowledge base trusts.
#[derive(Debug, Clone, PartialEq, serde::Deserialize, serde::Serialize)]
#[serde(deny_unknown_fields)]
pub struct GatewayConfigIdentity {
    /// The issuer URL, exactly as tokens carry it in `iss`.
    pub issuer: String,
    /// The claim a person's DID is built from: `did:web:<domain>:users:<its value>`.
    #[serde(rename = "subjectClaim")]
    pub subject_claim: String,
}

/// The signal plane: `in-process`, one gateway on its own fabric; or `nats`, the fabric every replica on one broker shares, which requires `servers` and a broker with JetStream.
#[derive(Debug, Clone, PartialEq, serde::Deserialize, serde::Serialize)]
#[serde(deny_unknown_fields)]
pub struct GatewayConfigSignal {
    pub r#type: GatewayConfigSignalType,
    /// The broker's address (`host:port`, or several, comma-separated). Required for `nats`.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub servers: Option<String>,
    /// The environment variable holding the broker user, when the broker requires one.
    #[serde(rename = "userEnv")]
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub user_env: Option<String>,
    /// The environment variable holding the broker password, when the broker requires one.
    #[serde(rename = "passwordEnv")]
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub password_env: Option<String>,
}

impl GatewayConfigSignal {
    /// The `GatewayConfigSignal` that states these and nothing else.
    pub fn new(r#type: GatewayConfigSignalType) -> Self {
        Self {
            r#type,
            servers: None,
            user_env: None,
            password_env: None,
        }
    }
}

#[derive(
    Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Hash, serde::Deserialize, serde::Serialize,
)]
pub enum GatewayConfigSignalType {
    #[serde(rename = "in-process")]
    InProcess,
    #[serde(rename = "nats")]
    Nats,
}

impl GatewayConfigSignalType {
    /// The value as the wire spells it.
    pub const fn as_str(&self) -> &'static str {
        match self {
            GatewayConfigSignalType::InProcess => "in-process",
            GatewayConfigSignalType::Nats => "nats",
        }
    }
}

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

/// A knowledge base's committed identity (`project.name` and `site.domain` in its .xynolog/config.yaml), as a service's document names the knowledge base it serves. Its telemetry names it by its DID (`xynolog.kb`, specs/src/service-telemetry/telemetry.json).
#[derive(Debug, Clone, PartialEq, serde::Deserialize, serde::Serialize)]
#[serde(deny_unknown_fields)]
pub struct KbIdentity {
    /// Its name. The gateway publishes it as its resource metadata's `resource_name`.
    pub name: String,
    /// Its did:web domain: its permanent identity, the source of the audience its tokens must carry, and the authority its people and agents are named under.
    pub domain: String,
}

schema!(KbIdentity);

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

/// The host and port a service listens at.
#[derive(Debug, Clone, PartialEq, serde::Deserialize, serde::Serialize)]
#[serde(deny_unknown_fields)]
pub struct ServiceAddress {
    pub host: String,
    pub port: u16,
}

schema!(ServiceAddress);

/// The identity provider a service's account signs in at, by its issuer.
#[derive(Debug, Clone, PartialEq, serde::Deserialize, serde::Serialize)]
#[serde(deny_unknown_fields)]
pub struct ServiceIdentity {
    /// The issuer URL, exactly as tokens carry it in `iss`.
    pub issuer: String,
}

schema!(ServiceIdentity);

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
