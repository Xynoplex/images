"""`python -m xynolog_weaver --config <path>`: the Weaver service, run as a process."""

import sys

from xynolog_weaver.service import main

if __name__ == "__main__":
    sys.exit(main())
