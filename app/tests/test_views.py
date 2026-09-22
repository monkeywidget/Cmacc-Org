import asyncio
import importlib
from urllib.parse import urlencode

import pytest


# - app wired to a throwaway store; views called through the real ASGI app, no HTTP client library
@pytest.fixture
def app(tmp_path, monkeypatch):
    (tmp_path / "G").mkdir()
    (tmp_path / "G" / "doc.md").write_text("r00t=Hello {Name} {Gone}\nName=World\n=[G/missing.md]\n")
    (tmp_path / "G" / "README.md").write_text("A folder.")
    monkeypatch.setenv("CMACC_STORE", str(tmp_path))
    monkeypatch.setenv("CMACC_REPO_URL", "")
    import cmacc.main
    return importlib.reload(cmacc.main).app


# - minimal ASGI call: status, headers, body
def call(app, method="GET", query=None, body=b""):
    scope = {"type": "http", "method": method, "path": "/i.php", "query_string": urlencode(query or {}).encode(),
             "headers": [(b"content-type", b"application/x-www-form-urlencoded")]}
    sent = []

    async def receive():
        return {"type": "http.request", "body": body, "more_body": False}

    async def send(message):
        sent.append(message)

    asyncio.run(app(scope, receive, send))
    start = next(m for m in sent if m["type"] == "http.response.start")
    return start["status"], dict(start["headers"]), b"".join(m.get("body", b"") for m in sent).decode()


# - every view renders without error for a document with a missing include
@pytest.mark.parametrize("view", ["d", "v", "p", "m", "o", "t", "x", "s", "j"])
def test_views_render(app, view):
    status, headers, body = call(app, query={"v": view, "f": "G/doc.md", "k": "r00t"})
    assert status == 200 and "Traceback" not in body
    assert headers[b"x-cmacc-missing-includes"] == (b"1" if view in "dvpmotx" else b"0")


# - Document view: resolved text, unresolved field highlighted, no repo link when unconfigured
def test_document_view(app):
    _, _, body = call(app, query={"v": "d", "f": "G/doc.md"})
    assert "World" in body and '<span class="missing">{Gone}</span>' in body and "GitHub" not in body


# - folder listing shows entries and the README
def test_list_view(app):
    _, _, body = call(app, query={"v": "l", "f": "G/"})
    assert "doc.md" in body and "A folder." in body


# - saving through the Source view rewrites the object (CRLF normalized, trimmed)
def test_save(app, tmp_path):
    form = urlencode({"v": "s", "f": "G/doc.md", "submit": "Save", "newcontent": "r00t=Saved\r\n\r\n"}).encode()
    status, _, _ = call(app, method="POST", body=form)
    assert status == 200 and (tmp_path / "G" / "doc.md").read_text() == "r00t=Saved"
