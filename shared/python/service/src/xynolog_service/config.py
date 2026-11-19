"""A service's configuration document, and what its environment holds beside it.

The document is a shape of the protocol: `WorkerConfig`, `WeaverConfig`,
`SmelterConfig`.
Whoever starts the service writes it, resolved: the launcher for the service
it starts, and anyone else to the same schema. So it is read and refused
here, and nothing is decided: no TOML is parsed, no `${VAR}` resolved, and no
value supplied that the document left out. A secret or a key is never in the
document. The document names the variable that holds it, or the variable is
the service's own, and the service reads its environment for it.

A refusal is worded as the gateway's, the Dispatcher's and the Archivist's
are, so an operator reads one kind of message from every service: it names
the service in lower case, as its image and its container are named. A
document the schema refuses is refused for the first fault every SDK finds in
it (`xynolog.required`), named by the way to its member, and never by a value
found in the document: a secret written where its variable's name belongs is
such a value.
"""

from collections.abc import Mapping, Sequence
from pathlib import Path
from typing import Final

from pydantic import JsonValue, TypeAdapter, ValidationError
from xynolog.http import KeyCredential, NotAnRsaKey, SecretCredential, UnreadableKey, private_key_from_pem
from xynolog.model import WireModel
from xynolog.required import UNDECODED, Fault, as_read

__all__ = ["Refused", "config_path_of", "key_account_of", "read_config", "service_account_of", "set_in"]


class Refused(Exception):
    """Why the service does not start. Its words are what it says, once, before it exits."""


def config_path_of(service: str, arguments: Sequence[str]) -> str:
    """The path the service was started with: what follows `--config`, or is joined to it by `=`.

    It is never guessed. A path the service assumed would hide a deployment
    that put the document somewhere else.
    """
    for at, argument in enumerate(arguments):
        if argument.startswith("--config="):
            path = argument.removeprefix("--config=")
            if path:
                return path
        elif argument == "--config" and at + 1 < len(arguments):
            path = arguments[at + 1]
            if path and not path.startswith("--"):
                return path
    raise Refused(f"The {service}'s configuration document is not named: start it with --config <path>")


_JSON: Final = TypeAdapter[JsonValue](JsonValue)


def _reason(fault: Fault) -> str:
    """The fault, as the line an operator reads: a member the document lacks by its own name, any other by the way to it."""
    if fault.reason == "lacks":
        return f"Missing required property: {fault.member.rsplit('.', 1)[-1]}"
    return f"{fault.member or 'root'}: is not what the schema states"


def read_config[C: WireModel](service: str, shape: type[C], path: str) -> C:
    """The document at `path`, as the shape of the protocol that `shape` is: read, and held to its schema before it is believed.

    The schema is held as it is written, by the rules every SDK reads it by. A
    member is known by the name the document gives it and by no other, and a
    value is the kind the schema states: a number written as text is no number.
    """
    try:
        written = Path(path).read_bytes()
    except OSError as unread:
        raise Refused(
            f"Cannot read the {service}'s configuration document at {path} ({unread}). "
            f"The launcher writes it; a {service} started another way is given one ({shape.__name__} in protocol/specs/)."
        ) from unread
    try:
        value = _JSON.validate_json(written)
    except ValidationError as unparsed:
        (refusal,) = unparsed.errors(include_url=False, include_input=False)
        raise Refused(f"{path} is not JSON: {refusal['msg'].removeprefix('Invalid JSON: ')}") from None
    read = as_read(shape, value)
    if not isinstance(read, Fault):
        try:
            return shape.model_validate(read, by_alias=True, by_name=False)
        except ValidationError:
            read = UNDECODED
    raise Refused(f"{path} is not a {service} configuration document ({shape.__name__}):\n  {_reason(read)}") from None


def set_in(environment: Mapping[str, str], name: str) -> str | None:
    """What `environment` holds for the variable `name`. `None` where it holds nothing: a variable set to nothing is not set."""
    return environment.get(name) or None


def _held(service: str, environment: Mapping[str, str], name: str) -> str:
    value = set_in(environment, name)
    if value is None:
        raise Refused(f"{name} is not set in the {service}'s environment: a {service} signs in as a service account")
    return value


def service_account_of(service: str, issuer: str, environment: Mapping[str, str]) -> SecretCredential:
    """The service's own account at `issuer`, which its document names, proven by its client secret."""
    return SecretCredential(
        issuer=issuer,
        client_id=_held(service, environment, "XYNOLOG_OIDC_CLIENT_ID"),
        client_secret=_held(service, environment, "XYNOLOG_OIDC_CLIENT_SECRET"),
    )


def key_account_of(service: str, issuer: str, client_id: str, environment: Mapping[str, str]) -> KeyCredential:
    """The service's account at `issuer`, the client `client_id` that its document names there, proven by its key.

    `XYNOLOG_OIDC_CLIENT_KEY` holds the key: an RSA private key, PKCS#8 PEM
    and unencrypted. Which client holds its public half at an issuer is the
    document's to say. A refusal names the variable and never what it holds.
    """
    pem = _held(service, environment, "XYNOLOG_OIDC_CLIENT_KEY")
    try:
        key = private_key_from_pem(pem)
    except UnreadableKey:
        raise Refused(f"XYNOLOG_OIDC_CLIENT_KEY in the {service}'s environment is not an unencrypted PEM private key") from None
    except NotAnRsaKey:
        raise Refused(
            f"XYNOLOG_OIDC_CLIENT_KEY in the {service}'s environment is not an RSA key: a {service} signs its assertions with RS256"
        ) from None
    return KeyCredential(issuer=issuer, client_id=client_id, private_key=key)
