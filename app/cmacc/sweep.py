import argparse
import signal
import sys
from concurrent.futures import ProcessPoolExecutor
from pathlib import Path

from .engine import Renderer
from .store import Store


# - one template, one key, bounded time: ok / empty / error / timeout, plus missing-include count
# - missing includes are reported, not failures; "empty" = the key is not defined (e.g. a README)
def check(job):
    store_url, template, key, mode, seconds = job

    def expire(*_):
        raise TimeoutError

    sys.setrecursionlimit(20000)
    signal.signal(signal.SIGALRM, expire)
    signal.alarm(seconds)
    try:
        renderer = Renderer(Store(store_url), template, mode, remote=False)
        text = renderer.resolve(template, key) or ""
        status = "ok" if text.strip() else "empty"
        notes = [f"missing includes: {len(renderer.missing)}"] * bool(renderer.missing) + [f"budget cuts: {renderer.cut}"] * bool(renderer.cut)
        return status, template, "; ".join(notes)
    except TimeoutError:
        return "timeout", template, f"> {seconds}s"
    except Exception as error:
        return "error", template, f"{type(error).__name__}: {error}"
    finally:
        signal.alarm(0)


# - CLI: every template in the store (or the ones named), TSV on stdout, summary on stderr
# - exit 1 on any error or timeout: the acceptance bar is "every template renders without error"
def main():
    parser = argparse.ArgumentParser(description="Render every template; report ok/empty/error/timeout.")
    parser.add_argument("templates", nargs="*")
    parser.add_argument("--store", default="Doc")
    parser.add_argument("--key", default="r00t")
    parser.add_argument("--mode", default="doc", choices=["doc", "plain", "trace", "xray"])
    parser.add_argument("--timeout", type=int, default=20)
    parser.add_argument("--jobs", type=int, default=8)
    args = parser.parse_args()
    root = Path(args.store)
    templates = args.templates or sorted(str(p.relative_to(root)) for p in root.rglob("*.md") if p.is_file())
    counts = {}
    with ProcessPoolExecutor(args.jobs) as pool:
        for status, template, detail in pool.map(check, [(args.store, t, args.key, args.mode, args.timeout) for t in templates], chunksize=16):
            counts[status] = counts.get(status, 0) + 1
            print(f"{status}\t{template}\t{detail}")
    print(" ".join(f"{k}={v}" for k, v in sorted(counts.items())), file=sys.stderr)
    return 1 if counts.get("error") or counts.get("timeout") else 0


if __name__ == "__main__":
    sys.exit(main())
