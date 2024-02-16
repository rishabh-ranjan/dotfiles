try:
    import pdbr
except ImportError:
    pass

try:
    from rich.traceback import install

    install()
except ImportError:
    pass
