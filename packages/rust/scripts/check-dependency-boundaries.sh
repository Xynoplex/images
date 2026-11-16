#!/usr/bin/env bash
# check-dependency-boundaries.sh — what some crates must never link, as cargo
# resolves each crate's normal dependencies at its default features:
#
#   - xynolog-core, xynolog-http-service, xynolog-observability and
#     xynolog-dispatcher-handlers reach no NATS client. xynolog-core reaches
#     async-nats only through its `nats` feature, which a crate must ask for,
#     so with that feature it does: the one way in, and proof the check sees it.
#     scripts/check-broker-boundary.mjs holds the source side.
#   - xynolog-archivist-record reaches no network and runs no git: it links no
#     HTTP, git or NATS crate.
#
# Each crate is resolved alone (-p), so no other member's features unify into
# it. A dependency added anywhere below one of these crates fails here.
set -euo pipefail
# A cargo tree that fails, inside $(...), fails the script rather than leaving
# nothing to search.
shopt -s inherit_errexit
cd "$(dirname "$0")/.."

status=0

# linked <crate> <pattern> [<cargo tree argument>...]: the crates matching
# <pattern> among <crate>'s normal dependencies.
linked() {
  local crate="$1" pattern="$2" tree
  shift 2
  tree="$(cargo tree --locked -p "$crate" -e normal --prefix none "$@")"
  grep -E "^($pattern) v" <<<"$tree" | sort -u || true
}

refuse() {
  local crate="$1" pattern="$2" found
  found="$(linked "$crate" "$pattern")"
  if [[ -n "$found" ]]; then
    echo "$crate links what it must not:" >&2
    sed 's/^/    /' <<<"$found" >&2
    status=1
  fi
}

for crate in xynolog-core xynolog-http-service xynolog-observability xynolog-dispatcher-handlers; do
  refuse "$crate" 'async-nats'
done
reached="$(linked xynolog-core 'async-nats' --features nats)"
if [[ -z "$reached" ]]; then
  echo "xynolog-core's nats feature no longer reaches async-nats: the check above can no longer see the broker" >&2
  status=1
fi
refuse xynolog-archivist-record 'reqwest|hyper|axum|git2|gix|xynolog-http-[a-z]+|async-nats'

exit "$status"
