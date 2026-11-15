#!/usr/bin/env bash
# Boot a real stack and assert what the launcher's hermetic suite cannot.
#
#   tests/stack/smoke-stack.sh up local          # boot and check a stack of :local images; leave it up
#   tests/stack/smoke-stack.sh e2e               # run e2e's default tier beside it
#   tests/stack/smoke-stack.sh e2e --script test:slow --model gemma4:26b -- specs/01-sign-in.spec.ts
#                                                       # another npm script, a knowledge base bound to another
#                                                       # model, Playwright's arguments after --
#   tests/stack/smoke-stack.sh down              # stop it, and check every port is released
#   tests/stack/smoke-stack.sh run 0.6.5 --e2e   # all three in one run, as Stack Smoke does
#
# The launcher CLI is installed separately as `xynolog`; set XYNOLOG to use a
# specific executable. This repository owns only the images and their build.
# IMAGES is the tag `up` is given, written into the stack documents xynolog init
# creates. For `local`, build the images first with `make build`.
#
# UP asserts, and nothing more: that every health gate opens against a real
# service at a real route, that the realm the start CREATES through Keycloak's
# admin API answers, and that the realm allows the Browser's origin. Its
# knowledge base is exactly what a new user makes: `init` with only the did:web
# domain, then `start` with no --config, so the documents init writes and the
# Inference document it records are what boot. A new KB that could not start
# is the defect this check found on its first run. A failed `up` stops what it
# started; the launcher has already printed the last lines of the container
# whose health gate failed.
#
# E2E asks what a model does, which UP does not. Each run makes a knowledge
# base of its own beside UP's, as `init` makes one, with a domain no other run
# has, bound to init's model or the one --model names (init's is the smallest
# that serves a first knowledge base; @slow asks more of a model than it has),
# on the images UP's documents name: its start joins the shared
# containers UP's left running and gives it a gateway port of its own. It makes
# a user in that knowledge base's realm with `useradd`, then runs e2e's
# default tier less its @model tests (`npm run test:ci`, which typechecks the
# specs and leaves out @slow and @model), or the npm script --script names,
# with the arguments after -- given to Playwright, against its gateway, in the
# Playwright image whose tag is the version e2e/package.json pins. Then
# it reads the knowledge base's job queue from `xynolog status` until nothing
# is pending or running: a job the suite started that no worker claimed, or
# that none finished, fails the run though every test passed. On exit, when
# everything passed, it stops, cleans and forgets that knowledge base, leaving
# UP's running; when anything failed it leaves it running, its logs, jobs and
# traces there to read, and records it for DOWN. The suite's assertions are
# made against a knowledge base no earlier run touched: some of them hold only
# on a fresh one. The image reaches the stack at localhost
# through `--network host` on Docker and Podman, or the existing localhost
# bridge on Apple container. The suite's packages, @xynoplex/core and
# @xynoplex/sdk, link to this checkout's packages/, which must be built:
# scripts/build-session.sh builds them, as `npm run build:packages` does.
#
# DOWN stops, cleans, forgets and removes each knowledge base a failed E2E
# left, then stops UP's stack, puts back the Browser's and Worker's documents as UP
# found them (the launcher's own, if there were none), cleans the state,
# forgets the knowledge base in the launcher's registry, removes its directory
# (never one SMOKE_KB names), and asserts that every claimed port is released.
#
# THE STATE between them is UP's knowledge base, at SMOKE_KB or under the
# user's cache directory, with the machine's documents as UP found them beside
# it. The launcher keeps a KB's daemon state and secrets under a key derived
# from its domain, and UP's domain is the same on every run, so UP cleans that
# state before it boots (whatever an interrupted run left).
#
# Requires: a responding container runtime (CONTAINER_RUNTIME selects one), git, curl, nc.

set -uo pipefail

SELF="${BASH_SOURCE[0]}"
usage() {
  {
    echo "usage: $SELF up <images-tag>          e.g. $SELF up local"
    echo "       $SELF e2e [--script <npm-script>] [--model <model>] [-- <playwright-argument>...]"
    echo "       $SELF down"
    echo "       $SELF run <images-tag> [--e2e [--script <npm-script>] [--model <model>] [-- <playwright-argument>...]]"
  } >&2
  exit 2
}
COMMAND="${1:-}"
[ $# -gt 0 ] && shift
E2E=false
# What follows e2e's name, which run passes on to its e2e.
E2E_OPTIONS=()
case "$COMMAND" in
  up)
    [ $# -eq 1 ] && [ -n "$1" ] || usage
    IMAGES="$1" ;;
  run)
    [ $# -ge 1 ] && [ -n "$1" ] || usage
    IMAGES="$1"
    shift
    if [ $# -gt 0 ]; then
      [ "$1" = --e2e ] || usage
      shift
      E2E=true
      [ $# -eq 0 ] || E2E_OPTIONS=("$@")
    fi ;;
  e2e)
    E2E=true
    [ $# -eq 0 ] || E2E_OPTIONS=("$@") ;;
  down) [ $# -eq 0 ] || usage ;;
  *) usage ;;
esac
# The suite's npm script, the model e2e's knowledge base is bound to when init's is not the one, and
# Playwright's arguments.
SUITE_SCRIPT=test:ci
E2E_KB_MODEL=
SUITE_ARGUMENTS=()
set -- ${E2E_OPTIONS[@]+"${E2E_OPTIONS[@]}"}
while [ $# -gt 0 ]; do
  case "$1" in
    --script)
      [ $# -ge 2 ] && [ -n "$2" ] || usage
      SUITE_SCRIPT="$2"
      shift 2 ;;
    --model)
      [ $# -ge 2 ] && [ -n "$2" ] || usage
      E2E_KB_MODEL="$2"
      shift 2 ;;
    --)
      shift
      [ $# -eq 0 ] || SUITE_ARGUMENTS=("$@")
      break ;;
    *) usage ;;
  esac
done

if [ "$COMMAND" = run ]; then
  bash "$SELF" up "$IMAGES" || exit 1
  trap 'bash "$SELF" down >/dev/null; exit 1' INT TERM
  STATUS=0
  if [ "$E2E" = true ]; then bash "$SELF" e2e ${E2E_OPTIONS[@]+"${E2E_OPTIONS[@]}"} || STATUS=1; fi
  bash "$SELF" down || STATUS=1
  exit "$STATUS"
fi

REPO_ROOT="$(cd "$(dirname "$SELF")/../.." && pwd)"
source "$REPO_ROOT/scripts/container-runtime.sh"
RUNTIME=$(detect_container_runtime) || exit 2
E2E_NETWORK=(--network host --ipc host)
if [[ "$RUNTIME" == container ]]; then E2E_NETWORK=(); fi
if [ "$E2E" = true ]; then
  # Playwright refuses to run when the image and the library disagree, so the
  # tag is the version the suite pins, read here and never typed.
  PLAYWRIGHT=$(sed -n 's/^ *"@playwright\/test": "\(.*\)",\{0,1\}$/\1/p' "$REPO_ROOT/e2e/package.json")
  if ! printf '%s' "$PLAYWRIGHT" | grep -Eqx '[0-9]+\.[0-9]+\.[0-9]+'; then
    echo "e2e/package.json pins no exact @playwright/test version (read '$PLAYWRIGHT'), so no Playwright image can be named." >&2
    exit 2
  fi
fi
XYNOLOG="${XYNOLOG:-$(command -v xynolog || true)}"
if [ -z "$XYNOLOG" ] || [ ! -x "$XYNOLOG" ]; then
  echo "The stack smoke test needs the xynolog CLI. Install it or set XYNOLOG to its executable path." >&2
  exit 2
fi
# xynolog: the separately installed launcher CLI; show each invocation on fd 3.
exec 3>&1
xynolog() {
  { printf '  $ xynolog'; printf ' %q' "$@"; printf '\n'; } >&3
  "$XYNOLOG" "$@"
}

KB="${SMOKE_KB:-${XDG_CACHE_HOME:-$HOME/.cache}/semiont/stack-smoke/kb}"
# The machine's documents as UP found them: <service>.yaml, and <service>.path naming where it goes back.
KEPT="$KB/.smoke-kept"

PASS=0; FAIL=0
ok()    { printf '  \033[32mok\033[0m   %s\n' "$1"; PASS=$((PASS+1)); }
bad()   { printf '  \033[31mFAIL\033[0m %s\n' "$1"; FAIL=$((FAIL+1)); }
head_() { printf '\n\033[1m%s\033[0m\n' "$1"; }
summary() { printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"; [ "$FAIL" -eq 0 ]; }

# init_kb <directory> <domain> <images-tag> [<model>]: a knowledge base as a new
# user makes one, its documents naming the tag's images, bound to the model
# named or to init's. The images are the documents' to name: init names
# :latest, and the run names the set it was given, as a person choosing a
# release would.
init_kb() {
  local dir="$1" domain="$2" tag="$3" doc
  # The domain is the one setting with no safe default, so it is the one flag a new user's init needs.
  local flags=(--domain "$domain")
  [ $# -lt 4 ] || flags+=(--model "$4")
  head_ "A new knowledge base: xynolog init in $dir"
  echo "  launcher: $XYNOLOG ($(xynolog --version))"
  mkdir -p "$dir" && cd "$dir" || return 1
  git init -q && git config user.email smoke@example.com && git config user.name smoke
  if xynolog init --yes "${flags[@]}" >/dev/null; then
    ok "xynolog init ${flags[*]} made it, with a config the plan deriver accepts"
  else
    bad "xynolog init ${flags[*]} refused"; return 1
  fi
  for doc in "$dir"/.semiont/stack/*.yaml; do
    sed "s#\(ghcr.io/xynoplex/xynoplex-[a-z]*\):latest#\1:$tag#" "$doc" > "$doc.next" && mv "$doc.next" "$doc"
  done
  if [ "$tag" = latest ] || ! grep -q 'ghcr.io/xynoplex/xynoplex-[a-z]*:latest' "$dir"/.semiont/stack/*.yaml; then
    ok "the documents name the :$tag images"
  else
    bad "a document still names a :latest image"; return 1
  fi
}

# gateway_of <directory>: where clients reach that knowledge base's gateway,
# spec.gateway.publicURL of its KnowledgeBase document.
gateway_of() {
  awk '/^  gateway:/ { inside = 1; next } /^  [^ ]/ { inside = 0 } inside && /^    publicURL:/ { print $2; exit }' "$1/.semiont/stack/knowledge-base.yaml"
}

# start_kb: start the knowledge base standing here. No --config: a new KB
# records the config it was made with, and `start` reads that. Its defaults
# serve inference and embedding from Ollama: the host's when one answers,
# otherwise a container that pulls the two small models.
start_kb() {
  head_ "Boot from :$1 on $RUNTIME"
  if xynolog start --runtime "$RUNTIME"; then
    ok "every health gate opened against a real service"
  else
    bad "start failed: the launcher's reason is above"; return 1
  fi
}

# stop_kb <directory>: its stack alone. The shared containers stop with the
# last knowledge base recorded, so stopping E2E's leaves UP's running.
stop_kb() { xynolog stop --root "$1" --runtime "$RUNTIME" >/dev/null 2>&1; }

# forget_kb <directory> <removable>: clean a stopped knowledge base's state,
# forget it, and remove the directory above it when the run made that.
forget_kb() {
  local dir="$1" removable="$2"
  xynolog clean --root "$dir" >/dev/null 2>&1
  xynolog forget "$dir" >/dev/null 2>&1
  [ "$removable" = true ] && rm -rf "$(dirname "$dir")"
}

# restore_documents: put the machine's documents back as UP found them.
restore_documents() {
  local service
  for service in browser worker; do
    [ -f "$KEPT/$service.path" ] || continue
    mv "$KEPT/$service.yaml" "$(cat "$KEPT/$service.path")" && rm -f "$KEPT/$service.path"
  done
  rm -rf "$KEPT"
}

# down_kb: each knowledge base a failed E2E left, then UP's stack, stopped and
# gone, the machine's documents back. UP's stops last, since the shared
# containers stop with the last knowledge base recorded, and before the
# restore, so no Browser or Worker reads a document mid-restore.
down_kb() {
  local removable=true left
  [ -n "${SMOKE_KB:-}" ] && removable=false
  if [ -f "$KEPT/e2e" ]; then
    while IFS= read -r left; do
      [ -n "$left" ] || continue
      stop_kb "$left"
      forget_kb "$left" true
      echo "  removed $left, which a failed e2e left running"
    done < "$KEPT/e2e"
  fi
  stop_kb "$KB"
  restore_documents
  forget_kb "$KB" "$removable"
}

if [ "$COMMAND" = up ]; then
  if [ -e "$KEPT" ]; then
    echo "A stack from an earlier up is still recorded at $KB: take it down first (tests/stack/smoke-stack.sh down)." >&2
    exit 1
  fi
  SUCCEEDED=false
  trap 'cd / && [ "$SUCCEEDED" = true ] || down_kb' EXIT
  init_kb "$KB" example.github.io:stack-smoke "$IMAGES" || exit 1
  if xynolog clean --root "$KB" >/dev/null; then
    ok "no state from an earlier run remains"
  else
    bad "clean refused the state an earlier run left"; exit 1
  fi
  # The Browser and Worker are shared by the machine, so their images are
  # named in their own documents (`settings browser|worker --path`, which
  # writes one where there is none). DOWN restores both.
  mkdir -p "$KEPT" || exit 1
  for SERVICE in browser worker; do
    if ! SHARED_DOC=$(xynolog settings "$SERVICE" --path); then
      bad "the launcher named no $SERVICE document"; exit 1
    fi
    if ! cp "$SHARED_DOC" "$KEPT/$SERVICE.yaml"; then
      bad "could not keep a copy of $SHARED_DOC to put back"; exit 1
    fi
    printf '%s' "$SHARED_DOC" > "$KEPT/$SERVICE.path"
    sed "s#\(ghcr.io/xynoplex/xynoplex-$SERVICE\):[^[:space:]]*#\1:$IMAGES#" "$SHARED_DOC" > "$SHARED_DOC.next" && mv "$SHARED_DOC.next" "$SHARED_DOC"
    if grep -q "image: ghcr.io/xynoplex/xynoplex-$SERVICE:$IMAGES\$" "$SHARED_DOC"; then
      ok "$SERVICE's document names :$IMAGES"
    else
      bad "$SERVICE's document ($SHARED_DOC) does not name :$IMAGES"; exit 1
    fi
  done
  start_kb "$IMAGES" || exit 1

  head_ "Status"
  # `status --root` is the health-coded form: it exits non-zero when a core row
  # is unhealthy, so the exit status IS the assertion.
  if xynolog status --root "$KB"; then ok "every core row healthy"; else bad "a core row is unhealthy"; fi

  head_ "The realm the start created"
  # The knowledge base's realm is its key, made from the domain init was given.
  # A new KB's Keycloak holds no realm until the start creates it. The issuer is
  # where the gateway's protected-resource metadata (RFC 9728) sends a client to
  # sign in, as the Browser and the CLI learn it: the runtime decides the host
  # it is published on, so it is read, never assumed.
  REALM=example.github.io-stack-smoke
  ISSUER=$(curl -fs "$(gateway_of "$KB")/.well-known/oauth-protected-resource" \
    | grep -o '"authorization_servers"[^]]*' | grep -o 'https\{0,1\}://[^"]*' | head -1)
  case "$ISSUER" in
    */realms/"$REALM") ok "the gateway names realm '$REALM' at $ISSUER" ;;
    *) bad "the gateway names no issuer of realm '$REALM' (read '$ISSUER')" ;;
  esac
  if DISCOVERY=$(curl -fs "$ISSUER/.well-known/openid-configuration"); then
    ok "the issuer's discovery answers"
  else
    bad "the issuer's discovery does not answer at $ISSUER"
  fi
  # Keycloak names it again under mtls_endpoint_aliases, after the top-level one.
  TOKEN_ENDPOINT=$(printf '%s' "$DISCOVERY" | grep -o '"token_endpoint" *: *"[^"]*"' | head -1 | grep -o 'https\{0,1\}://[^"]*')

  head_ "The realm allows the Browser's origin"
  # BROWSER-SIGNIN-ORIGIN, live. The Browser exchanges its code from
  # http://localhost:3000, so Keycloak must echo that origin back. A bogus code
  # is fine — the CORS header is decided before the code is, which is what makes
  # this a one-variable test.
  HDR=$(curl -s -D- -o /dev/null -X POST \
    -H "Origin: http://localhost:3000" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    --data "grant_type=authorization_code&client_id=xynoplex-browser&code=bogus&redirect_uri=http://localhost:3000/en/auth/callback" \
    "$TOKEN_ENDPOINT" \
    | tr -d '\r' | grep -i '^access-control-allow-origin:')
  case "$HDR" in
    *"http://localhost:3000"*) ok "origin echoed: $HDR" ;;
    *) bad "the realm did not allow http://localhost:3000 — a freshly created realm cannot complete sign-in" ;;
  esac
  summary || exit 1
  SUCCEEDED=true
  echo "The stack is up from $KB. Run the e2e tier beside it with the e2e command; stop it with tests/stack/smoke-stack.sh down."
  exit 0
fi

if [ "$COMMAND" = down ]; then
  if [ ! -e "$KEPT" ]; then
    echo "No stack from up is recorded at $KB: nothing to take down." >&2
    exit 1
  fi
  head_ "Stop releases every claimed port"
  down_kb
  HELD=""
  for p in 4000 5432 7474 6333 8080 4222 24100 24101 24102 24103 24104 24105; do
    nc -z localhost "$p" 2>/dev/null && HELD="$HELD $p"
  done
  [ -z "$HELD" ] && ok "no stack port still held" || bad "still held:$HELD"
  summary
  exit
fi

# e2e
if [ ! -e "$KEPT" ] || ! xynolog status --root "$KB" >/dev/null 2>&1; then
  echo "No healthy stack from up at $KB: bring one up first (tests/stack/smoke-stack.sh up)." >&2
  exit 1
fi
IMAGES=$(grep -ho -m1 'ghcr.io/xynoplex/xynoplex-gateway:[^[:space:]]*' "$KB/.semiont/stack/knowledge-base.yaml" | sed 's/.*://')
if [ -z "$IMAGES" ]; then
  echo "$KB/.semiont/stack/knowledge-base.yaml names no gateway image, so the images up ran cannot be read." >&2
  exit 1
fi
RUN=$(od -An -N4 -tx1 /dev/urandom | tr -d ' \n')
E2E_KB="$(mktemp -d)/kb"
# finish_e2e: a run that passed leaves nothing behind. One that failed leaves
# its knowledge base running, its logs, jobs and traces there to read, and
# records it for DOWN to stop and remove.
finish_e2e() {
  cd / || return
  if [ "$FAIL" -eq 0 ]; then
    stop_kb "$E2E_KB"
    forget_kb "$E2E_KB" true
  else
    printf '%s\n' "$E2E_KB" >> "$KEPT/e2e"
    echo "Left the knowledge base at $E2E_KB running, to read what failed; tests/stack/smoke-stack.sh down stops and removes it."
  fi
}
trap finish_e2e EXIT
init_kb "$E2E_KB" "example.github.io:e2e-$RUN" "$IMAGES" ${E2E_KB_MODEL:+"$E2E_KB_MODEL"} || exit 1
start_kb "$IMAGES" || exit 1
# A port of its own beside up's.
GATEWAY=$(gateway_of "$E2E_KB")
if [ -z "$GATEWAY" ]; then
  bad "$E2E_KB/.semiont/stack/knowledge-base.yaml names no spec.gateway.publicURL"; exit 1
fi

head_ "npm run $SUITE_SCRIPT${SUITE_ARGUMENTS[@]+ -- ${SUITE_ARGUMENTS[*]}}, in mcr.microsoft.com/playwright:v$PLAYWRIGHT-noble, against $GATEWAY"
# A fresh realm has no users. The suite's is made here, with a password made
# here and known to nothing else, and both reach the suite under the names
# playwright.config.ts reads. The password goes to useradd on stdin and to
# the suite's container by name from this environment, never in an argument.
E2E_EMAIL=e2e@example.com
E2E_PASSWORD=$(od -An -N16 -tx1 /dev/urandom | tr -d ' \n')
export E2E_EMAIL E2E_PASSWORD
if ! printf '%s\n' "$E2E_PASSWORD" | xynolog useradd --email "$E2E_EMAIL" --runtime "$RUNTIME" >/dev/null; then
  bad "useradd refused $E2E_EMAIL, so the suite has no one to sign in as"; exit 1
fi
ok "useradd made $E2E_EMAIL in the realm"
# e2e is not a root workspace, so its dependencies are its own. The
# JSON report beside the list and HTML ones is for whoever summarises the
# run: PLAYWRIGHT_JSON_OUTPUT_NAME is Playwright's, and test-results/ is
# the suite's output directory, emptied when a run begins.
STARTED=$SECONDS
if "$RUNTIME" run --rm -m 8g ${E2E_NETWORK[@]+"${E2E_NETWORK[@]}"} \
  -v "$REPO_ROOT":/workspace -w /workspace/e2e \
  -e E2E_EMAIL -e E2E_PASSWORD \
  -e E2E_BROWSER_URL=http://localhost:3000 \
  -e "E2E_GATEWAY_URL=$GATEWAY" \
  -e PLAYWRIGHT_JSON_OUTPUT_NAME=test-results/report.json \
  -e CI=1 \
  "mcr.microsoft.com/playwright:v$PLAYWRIGHT-noble" \
  sh -c '
    set -e
    runtime=$1
    script=$2
    shift 2
    npm ci
    if [ "$runtime" = container ]; then
      node e2e-localhost-bridge.mjs &
      bridge_pid=$!
      trap "kill $bridge_pid 2>/dev/null || true" EXIT
      sleep 1
      kill -0 "$bridge_pid"
    fi
    npm run "$script" -- --reporter=list,html,json "$@"
  ' sh "$RUNTIME" "$SUITE_SCRIPT" ${SUITE_ARGUMENTS[@]+"${SUITE_ARGUMENTS[@]}"}; then
  ok "npm run $SUITE_SCRIPT passed ($((SECONDS - STARTED))s)"
else
  bad "npm run $SUITE_SCRIPT failed ($((SECONDS - STARTED))s): e2e/playwright-report holds the report"
fi

head_ "The knowledge base's job queue, after the suite"
# A job the suite started that no worker claimed, or that none finished, is a
# failure no test sees. Status reads the queue from the collector, which holds
# what the dispatcher last exported, up to 30 seconds old, so it is read until
# it reads empty, for two minutes.
QUEUE=""
for ATTEMPT in 1 2 3 4 5 6 7 8 9 10 11 12; do
  QUEUE=$(xynolog status --root "$E2E_KB" 2>/dev/null \
    | sed -n 's/^ *queue  *\([0-9][0-9]*\) pending[^0-9]*\([0-9][0-9]*\) running.*/\1 \2/p')
  [ "$QUEUE" = "0 0" ] && break
  [ "$ATTEMPT" -eq 12 ] || sleep 10
done
case "$QUEUE" in
  "0 0") ok "nothing pending or running" ;;
  "") bad "xynolog status printed no queue line for the knowledge base's dispatcher" ;;
  *) bad "${QUEUE% *} pending and ${QUEUE#* } running two minutes after the suite: a job it started was never claimed, or never finished" ;;
esac
summary
