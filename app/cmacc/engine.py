import re
from html import escape
from http.client import HTTPException
from urllib.request import urlopen

PLACEHOLDER = re.compile(r"\{([^}]+)\}")
INCLUDE = re.compile(r"^([^=]*)=\[(.+?)\]")
SENTINEL = re.compile(r"^\s*</test>\s*$")
MAX_NESTING = 1_000
MAX_STEPS = 1_000_000
MAX_CHARS = 5_000_000


# - legacy truth rule: "" and "0" count as not found, so the search continues and the placeholder stays
def found(value):
    return value is not None and value not in ("", "0")


# - one object file: first value per key (first writer wins) and its include lines, in order
class Record:
    def __init__(self, text):
        self.values, self.includes = {}, []
        for line in text.split("\n"):
            key, eq, value = line.partition("=")
            if eq:
                self.values.setdefault(key.rstrip(), value.lstrip())
            match = INCLUDE.match(line)
            if match:
                self.includes.append(match.groups())


# - one render pass over a root document, following the legacy parser's lookup rules
# - adds what the legacy parser lacked: a loop guard, and missing includes reported instead of fatal
# - mode = how resolved values are marked: doc (depth spans), plain, trace, xray
class Renderer:
    def __init__(self, store, root, mode="doc", remote=True, timeout=20):
        self.store, self.root, self.mode = store, root, mode
        self.remote, self.timeout = remote, timeout
        self.files, self.missing, self.visits, self.active = {}, [], [], set()
        self.steps = self.cut = 0

    # - parsed object by store path or URL, read once per render; None (and recorded) when unavailable
    def record(self, target):
        if target not in self.files:
            try:
                self.files[target] = Record(self.fetch(target) if target.startswith("http") else self.store.read(target))
            except (OSError, ValueError, HTTPException):
                self.files[target] = None
                self.missing.append(target)
        return self.files[target]

    # - remote include read into memory with a timeout; no temp files, no shell
    def fetch(self, url):
        if not self.remote:
            raise OSError("remote includes disabled")
        with urlopen(url, timeout=self.timeout) as response:
            return response.read().decode("utf-8", "surrogateescape")

    # - expanded value of key in target, or None
    # - re-entering the same (file, key, prefix) means a loop: treated as unresolved
    # - budgets stop runaway templates (loops that grow the prefix, exponential fan-out):
    # - nesting depth and total lookups per render; anything past a budget stays unresolved and is counted
    def resolve(self, target, key, prefix="", depth=0):
        record = self.record(target)
        token = (target, key, prefix)
        if record is None or token in self.active:
            return None
        self.steps += 1
        if len(self.active) >= MAX_NESTING or self.steps > MAX_STEPS:
            self.cut += 1
            return None
        self.active.add(token)
        try:
            content = self.lookup(record, key, prefix, depth)
            return self.expand(content, prefix, depth) if found(content) else None
        finally:
            self.active.discard(token)

    # - the file's own line wins; otherwise the first include whose prefix starts the key
    # - the prefix is stripped from the key going in and accumulated for placeholders coming out
    def lookup(self, record, key, prefix, depth):
        if key in record.values:
            return record.values[key]
        for part, target in record.includes:
            if not key.startswith(part):
                continue
            rest = key[len(part):] if part and len(key) > len(part) else key
            value = self.resolve(target, rest, prefix + part, depth)
            self.visits.append((prefix + part, key, target, value))
            if found(value):
                return value
        return None

    # - each {name} resolves from the root document as prefix + name; unresolved names stay as written
    def expand(self, content, prefix, depth):
        for name in dict.fromkeys(PLACEHOLDER.findall(content)):
            key = prefix + name
            raw = key.endswith("!!")
            value = self.resolve(self.root, key[:-2] if raw else key, "", depth + 1)
            if not found(value):
                continue
            if SENTINEL.match(value):
                value = ""
            elif not raw:
                value = self.mark(key, value, depth + 1)
            if len(content) + len(value) > MAX_CHARS:
                self.cut += 1
                continue
            content = content.replace("{" + name + "}", value)
        return content

    # - how a resolved value appears in the output, per mode
    def mark(self, key, value, depth):
        k = escape(key)
        if self.mode == "doc":
            return (f"<span title='{k}' id='{k}' data-depth='{depth}' data-cmacc-title='{k}' class='cmacc-span'>"
                    f"<span class='cmacc-content'>{value}</span></span>")
        if self.mode == "trace":
            return f'<span title="{k}" id="{k}" >{value}</span>'
        if self.mode == "xray":
            return f'<span title="{k}" id="{k}" >(<b>{k}</b> = {value})</span><br>'
        return value


# - unresolved placeholders in output order, each once
def unresolved(text):
    return list(dict.fromkeys(PLACEHOLDER.findall(text)))


# - suggested parameters for the open-parameters view, using the corpus naming conventions
def suggestions(names):
    lines = []
    for n in names:
        if n.startswith("DefT."):
            lines.append(f"{n[5:]}=<a class='definedterm' href='{{!!!}}DefT.{n[5:]}'>{n[5:].replace('_', ' ')}</a>")
        elif n.startswith("_"):
            lines.append(f"{n[1:]}=<a class='definedterm' href='{{!!!}}DefT.{n[1:]}'>{n[1:].replace('_', ' ')}</a>")
        elif n.startswith("FtNt."):
            lines.append(f"{n}=<sup><a class='xref' href='{{!!!}}{n[:-5]}.sec'>{n[5:-5]}</a></sup>")
        elif n.endswith(".Xnum"):
            lines.append(f"{n}=<a class='xref' href='{{!!!}}{n[:-5]}.sec'>{n[:-5]}</a>")
        else:
            lines.append(f"{n}=")
    return "\n".join(lines) + ("\n" if lines else "")
