import datetime
import mimetypes
import posixpath
import re
import sys
from functools import lru_cache
from urllib.parse import parse_qs

from fastapi import FastAPI, Request
from fastapi.responses import Response
from fastapi.staticfiles import StaticFiles
from markupsafe import Markup

from .engine import PLACEHOLDER, Renderer, unresolved
from .pages import marks, pages
from .settings import Settings
from .store import Store

VIEWS = {"d": "doc", "v": "visual", "c": "visual", "p": "print", "m": "missing", "o": "openedit",
         "t": "trace", "x": "xray", "s": "source", "j": "json", "l": "list"}
DOC_VIEWS = {
    "doc": ("doc", "Doc.css", True, True), "visual": ("doc", "Visual.css", True, False),
    "print": ("plain", "Print.css", False, False), "missing": ("plain", "Doc.css", True, False),
    "trace": ("trace", "Doc.css", True, False), "xray": ("xray", "Doc.css", True, False),
    "openedit": ("plain", "Doc.css", True, False),
}

sys.setrecursionlimit(20000)
settings = Settings()
store = Store(settings.store)
BRACE_OPEN, BRACE_CLOSE = str(marks.brace_open()), str(marks.brace_close())  # marks.html: <span class="missing">{ … }</span>
app = FastAPI(title="CommonAccord", docs_url=None, redoc_url=None)
for route, folder in [("/File", settings.files), ("/png", f"{settings.static}/png"),
                      ("/image", f"{settings.static}/image"), ("/vendor/png", f"{settings.static}/vendor/png")]:
    app.mount(route, StaticFiles(directory=folder, check_dir=False))


# - repo links (GitHub, Compare) only when a repo is configured; Compare only for GitHub repos
@lru_cache
def repo():
    slug = re.match(r"^https://github\.com/([^/]+/[^/]+?)/?$", settings.repo_url)
    docs = f"{settings.repo_url}/blob/{settings.repo_branch}/Doc/" if settings.repo_url else ""
    return {"docs": docs, "slug": slug.group(1) if slug else ""}


# - one render; head stylesheet from the document's CSS.Special key when it sets one
def render(path, key, mode):
    renderer = Renderer(store, path, mode, settings.remote_includes, settings.remote_timeout)
    text = renderer.resolve(path, key) or ""
    css = Renderer(store, path, "plain", settings.remote_includes, settings.remote_timeout).resolve(path, "CSS.Special")
    return text, renderer, css


# - HTML response; undecodable corpus bytes pass through; missing includes in a header, not in the page
def html(text, missing=()):
    headers = {"X-Cmacc-Missing-Includes": str(len(missing))}
    return Response(text.encode("utf-8", "surrogateescape"), media_type="text/html; charset=utf-8", headers=headers)


# - document-style views: one engine pass, view-specific marking and post-processing
# - DOC_VIEWS per view: engine mode, default stylesheet, tabs shown, depth control shown
def document_view(view, path, key, context):
    mode, default_css, tabs, depth = DOC_VIEWS[view]
    key = key if len(key) >= 2 else "r00t"
    text, renderer, css = render(path, key, mode)
    if view == "openedit":
        return html(pages.get_template("openedit.html").render(  # suggestion lines via marks.suggest
            context, names=unresolved(text), existing=store.read(path),
            stamp=datetime.date.today().strftime("%Y/%m/%d")), renderer.missing)
    if view == "missing":
        text = pages.get_template("missing.html").render(names=unresolved(text))  # "name=<br><br>" per unresolved field
    elif view == "trace":
        text = pages.get_template("trace.html").render(visits=reversed(renderer.visits))  # <table> of includes visited
    text = text.replace("{Render.Metadata}", f"({path}#{key} on {datetime.date.today():%Y-%m-%d})")
    if view == "print":
        text = text.replace("(Curly-)", "{").replace("(-Curly)", "}")
    else:
        text = text.replace("{", BRACE_OPEN).replace("}", BRACE_CLOSE)  # highlight every unresolved {field}
    page = pages.get_template("document.html").render(  # <head> stylesheet, tab bar, depth control, body
        context, css=css or f"Doc/G/Z/CSS/{default_css}", tabs=tabs, depth=depth,
        body=Markup(text) if len(text.strip()) > 1 else None, missing=renderer.missing)
    return html(page, renderer.missing)


# - source lines as data for source.html: what kind of key and value each line has
# - value kinds: remote / folder / include links, or text whose {placeholders} become links
# - parts alternate text and placeholder names (re.split with a capture group)
def source_rows(text):
    rows = []
    for line in text.split("\n"):
        key, _, rest = line.partition("=")
        value, _, comment = rest.partition("///")
        if not (key or value):
            continue
        link = (re.search(r"\[(http.+?)\]", value) and "remote") or (re.search(r"\[(.+?)/\]", value) and "folder") \
            or (re.match(r"\[(.+?)\]", value) and "include") or "text"
        target = re.search(r"\[(.+?)/?\]", value)[1] if link != "text" else None
        key_kind = "plain" if re.search(r"\s", key) or key.endswith(":") else "expand" if key.endswith(".") else "term"
        # source.html: key_kind picks the key cell's <a>; link picks the value cell's <a>; parts become placeholder links
        rows.append({"key": key, "key_kind": key_kind, "value": Markup(value), "link": link, "target": target,
                     "parts": PLACEHOLDER.split(value), "comment": Markup(comment)})
    return rows


# - JSON-ish view as data: include edges, then key/values split into text and placeholder names
def json_parts(text):
    edges, data = [], []
    for line in text.split("\n"):
        key, eq, value = line.partition("=")
        if m := re.search(r"\[(.+?)\]", value):
            edges.append((key, m[1]))  # json.html: "edges" list, target linked
        elif eq:
            data.append((key, PLACEHOLDER.split(value)))  # json.html: "data" list, names in <b>
    return edges, data


# - folder listing: intro page, subfolders, files, README paragraphs; repo link when configured
def list_view(folder, context):
    folder = folder if folder.endswith("/") or not folder else folder + "/"
    intro = next((store.read(folder + n) for n in ("listintro.html", "list.html") if store.isfile(folder + n)), None)
    entries = [(n, d) for n, d in store.listdir(folder)
               if not (n.startswith(".") or (not d and n in ("list.html", "listintro.html")))]
    readme = store.read(folder + "README.md") if store.isfile(folder + "README.md") else ""
    paragraphs = [Markup(p) for p in re.split(r"\n\r\n\r|\n\n|\r\r", readme)] if readme else []  # list.html joins with <br>
    parent = posixpath.dirname(folder.rstrip("/"))
    return html(pages.get_template("list.html").render(  # breadcrumb, intro, entry links, README
        context, folder=folder, parent=parent, name=posixpath.basename(folder.rstrip("/")),
        intro=Markup(intro) if intro else None, entries=entries, readme=paragraphs))


# - legacy save: overwrite an existing object with normalized line endings, trimmed
def save(path, content):
    try:
        store.write(path, content.replace("\r\n", "\n").strip())
        return None
    except FileNotFoundError:
        return f"ERROR: File {path} does not exists."


# - single entry point, same URLs as the legacy app: i.php?v=<view>&f=<file>&k=<key>
@app.api_route("/", methods=["GET", "POST"])
@app.api_route("/i.php", methods=["GET", "POST"])
@app.api_route("/index.php", methods=["GET", "POST"])
async def dispatch(request: Request):
    params = {k: v[-1] for k, v in parse_qs(request.url.query, keep_blank_values=True).items()}
    if request.method == "POST":
        body = (await request.body()).decode("utf-8", "surrogateescape")
        params |= {k: v[-1] for k, v in parse_qs(body, keep_blank_values=True).items()}
    raw_view = params.get("v", "landing")
    view = VIEWS.get(raw_view, raw_view)
    key = params.get("k", "r00t")
    path = re.sub(r"[^\w/.,_-]", "_", params.get("f", "")).replace("..", "")
    context = {"path": path, "key": key, "name": posixpath.basename(path), "folder": posixpath.dirname(path),
               "repo": repo()}
    if view == "landing":
        text, renderer, _ = render(settings.landing, key if len(key) >= 2 else "r00t", "doc")
        return html(text if len(text) > 1 else "Nothing to Show", renderer.missing)
    if view in DOC_VIEWS:
        return document_view(view, path, key, context)
    if view == "list":
        return list_view(path, context)
    error = save(path, params.get("newcontent", "")) if "submit" in params and view in ("source", "json") else None
    if not store.isfile(path):
        return html(pages.get_template("message.html").render(context, message=f"No such document: {path}"))  # <h3> message
    text = store.read(path)
    if view == "json":
        edges, data = json_parts(text)
        return html(pages.get_template("json.html").render(context, edges=edges, data=data, error=error))  # edges + data lists
    notice = None if view == "source" else "That is not a valid 'view'. Try 'v=s' or 'v=l' etc."
    return html(pages.get_template("source.html").render(context, rows=source_rows(text), error=error, notice=notice))  # key = value table


# - corpus files (stylesheets, images) by their Doc/ path, served from the template store
@app.get("/Doc/{rel:path}")
def corpus_file(rel: str):
    if not store.isfile(rel):
        return Response(status_code=404)
    data = store.read(rel).encode("utf-8", "surrogateescape")
    return Response(data, media_type=mimetypes.guess_type(rel)[0] or "application/octet-stream")
