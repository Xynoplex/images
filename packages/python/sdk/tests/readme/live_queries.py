from typing import assert_never

from xynoplex.cache import Failed, Pending, Ready
from xynoplex.client import SemiontClient
from xynoplex.errors import SemiontError
from xynoplex.identifiers import ResourceId
from xynoplex.transport import Transport


async def watch(client: SemiontClient[Transport], resource: ResourceId) -> None:
    async with client.browse.annotations(resource) as live:  # holds the resource's scope
        async for state in live:
            match state:
                case Pending():
                    print("asking")
                case Ready(value=annotations):
                    print(len(annotations), "annotations")
                case Failed(error=SemiontError() as error):  # a state, not a raise: the query lives on
                    print("failed:", error.code)
                case Failed(error=error):  # whatever else the request failed with
                    print("failed:", error)
                case _:
                    assert_never(state)
