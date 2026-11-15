"""`python -m xynolog_librarian --config <path>`: the Librarian service, run as a process."""

import sys

from xynolog_librarian.service import main

if __name__ == "__main__":
    sys.exit(main())
