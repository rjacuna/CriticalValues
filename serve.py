#!/usr/bin/env python3
"""Development server.

Serves web/ and forwards POST /solve to the native `critjson` binary, one line
in, one line out, over a single warm process. It does no mathematics — it is a
pipe. When the wasm cross-compiler is available this whole file goes away and
the front end calls the wasm module instead; the JSON contract is identical, so
that is a one-line change in web/js/backend.js.

    ./serve.py [--port 8000]
"""
import argparse, http.server, json, os, subprocess, threading, sys, pathlib

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parent


def find_binary():
    """Optional. Once web/crit.wasm exists the page runs the construction in
    the browser and never posts here, so a missing critjson is not fatal."""
    hits = sorted(ROOT.glob("dist-newstyle/**/critjson"))
    hits = [h for h in hits if h.is_file() and os.access(h, os.X_OK)]
    return hits[-1] if hits else None


class Backend:
    """One warm process, serialised. Restarts if it ever dies."""

    def __init__(self, path):
        self.path = path
        self.lock = threading.Lock()
        self.proc = None
        self.mtime = None

    def _spawn(self):
        self.mtime = self.path.stat().st_mtime
        self.proc = subprocess.Popen(
            [str(self.path)], stdin=subprocess.PIPE, stdout=subprocess.PIPE,
            text=True, encoding="utf-8", bufsize=1)

    def _stale(self):
        """A `cabal build` while the server runs would otherwise leave the warm
        process serving the previous binary — silently, and confusingly."""
        try:
            return self.mtime is not None and self.path.stat().st_mtime != self.mtime
        except OSError:
            return False

    def solve(self, wire):
        with self.lock:
            if self.proc is not None and self._stale():
                print("critjson rebuilt — restarting backend")
                try:
                    self.proc.kill()
                except Exception:
                    pass
                self.proc = None
            if self.proc is None or self.proc.poll() is not None:
                self._spawn()
            try:
                self.proc.stdin.write(wire.replace("\n", "") + "\n")
                self.proc.stdin.flush()
                line = self.proc.stdout.readline()
            except (BrokenPipeError, ValueError):
                self._spawn()
                self.proc.stdin.write(wire.replace("\n", "") + "\n")
                self.proc.stdin.flush()
                line = self.proc.stdout.readline()
            if not line:
                return json.dumps({"ok": False, "error": "backend produced no output"})
            return line.strip()


class Handler(http.server.SimpleHTTPRequestHandler):
    backend = None

    def __init__(self, *a, **kw):
        super().__init__(*a, directory=str(HERE), **kw)

    def do_POST(self):
        if self.path.rstrip("/") != "/solve":
            self.send_error(404)
            return
        n = int(self.headers.get("Content-Length", 0))
        try:
            wire = json.loads(self.rfile.read(n) or b"{}").get("wire", "")
        except Exception:
            self.send_error(400, "bad JSON")
            return
        if self.backend.path is None:
            out = json.dumps({"ok": False,
                              "error": "no backend: build crit.wasm, or cabal build critjson"}).encode()
        else:
            out = self.backend.solve(wire).encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(out)))
        self.end_headers()
        self.wfile.write(out)

    def log_message(self, fmt, *args):
        if self.command == "POST":
            super().log_message(fmt, *args)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--port", type=int, default=8000)
    args = ap.parse_args()
    Handler.backend = Backend(find_binary())
    wasm = HERE / "crit.wasm"
    print(f"crit.wasm: {'present — the page will run in-browser' if wasm.exists() else 'absent'}")
    print(f"critjson:  {Handler.backend.path or 'not built (only needed without crit.wasm)'}")
    print(f"serving:  http://localhost:{args.port}/")
    http.server.ThreadingHTTPServer(("127.0.0.1", args.port), Handler).serve_forever()


if __name__ == "__main__":
    main()
