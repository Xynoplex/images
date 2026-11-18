# Generated from protocol/specs/src/archivist/openapi.json; do not edit.
# Regenerate: make generate (xynolog/sdk's codegen/lib/images/archivist_waits.ml)
# ruff: noqa: E501, I001, RUF002, RUF022, RUF100

"""How long a caller waits for the Archivist: its document's `x-xynolog-limits`."""

from typing import Final

__all__ = ["CONNECT_SECONDS", "READ_SECONDS"]

# How long the Archivist is given to take a connection (`connectSeconds`).
CONNECT_SECONDS: Final = 5

# How long the Archivist is given for each part of an answer (`readSeconds`): for the answer to
# begin once its request is sent whole, and for each next part. No bound is put on a whole
# answer.
READ_SECONDS: Final = 20
