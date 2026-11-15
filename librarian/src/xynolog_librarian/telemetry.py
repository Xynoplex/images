"""What the Librarian tells OpenTelemetry of its own work: the gathers that went without something.

`protocol/contract/LIBRARIAN.md` § The two waits states the counter,
`xynolog.gather.degraded`, and the three values of its `projection`: `graph`
and `vectors`, the two waits that ran out, and `suggestions`, a summary a
model failed to give.

It takes OpenTelemetry's API and nothing more, so counting does nothing until
the process it runs in installs a provider (`xynolog_service.observability`).
What a driver records of a request of a model is the driver's own, what is
told of each frame is the SDK's, and what the process says of itself is
`xynolog_service.observability`'s.
"""

from typing import Final, final, override

from opentelemetry import metrics

from xynolog_librarian.reads import Degraded, Projection

__all__ = ["GatherDegraded"]

_SCOPE: Final = "xynolog"
_METER: Final = metrics.get_meter(_SCOPE)
_DEGRADED: Final = _METER.create_counter(
    "xynolog.gather.degraded", description="Gathers that went without something, by what each went without"
)


@final
class GatherDegraded(Degraded):
    """What counts a gather that went without something, on the counter `xynolog.gather.degraded`."""

    @override
    def note(self, projection: Projection) -> None:
        _DEGRADED.add(1, {"projection": projection})
