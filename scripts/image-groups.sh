#!/bin/sh
# image-groups.sh <variable> — the images one of the Makefile's groups names,
# on one line: RUST_IMAGES, TYPESCRIPT_IMAGES, PYTHON_IMAGES, or IMAGE_NAMES
# for all of them.
#
# The Makefile is the one place the groups are written. This reads one of
# them through a one-target makefile on stdin, which prints the variable and
# runs nothing of the Makefile's own. A variable that names no image fails.
set -eu
VARIABLE="${1:?usage: image-groups.sh <variable>}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
images=$(printf 'print-%%:\n\t@echo $($*)\n' | make -s --no-print-directory -C "$ROOT" -f Makefile -f - "print-$VARIABLE")
if [ -z "$images" ]; then
  echo "image-groups.sh: the Makefile's $VARIABLE names no image" >&2
  exit 1
fi
echo "$images"
