from pathlib import Path
import sys

try:
    tmp = str(
        next(Path("~/.mambaforge/lib").expanduser().glob("python*")) / "site-packages"
    )
    sys.path.append(tmp)
except:
    pass

try:
    import pdbr

except ImportError:
    pass

try:
    from rich.traceback import install

    install()
except ImportError:
    pass

sys.path.pop()
