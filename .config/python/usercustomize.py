from pathlib import Path
import sys

try:
    p = (
        next(Path("~/.micromamba/envs/sw/lib").expanduser().glob("python*"))
        / "site-packages"
    )
    sys.path.append(str(p))
    append = True
except:
    append = False

try:
    import pdbr

except ImportError:
    pass

# try:
#     # from rich.console import Console
#     from rich.traceback import install

#     # install(console=Console(no_color=True))
#     install()
# except ImportError:
#     pass

if append:
    sys.path.pop()
