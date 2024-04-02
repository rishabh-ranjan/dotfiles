from pathlib import Path
import sys

try:
    p = next(Path("~/.mambaforge/lib").expanduser().glob("python*")) / "site-packages"
    sys.path.append(str(p))
except:
    pass

try:
    import pdbr

except ImportError:
    pass

try:
    from rich.console import Console
    from rich.traceback import install

    install(console=Console(no_color=True))
except ImportError:
    pass

sys.path.pop()
