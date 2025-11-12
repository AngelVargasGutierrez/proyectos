import os
import re
import base64
import requests
from dotenv import load_dotenv

load_dotenv()

GITHUB_TOKEN = os.getenv("GITHUB_TOKEN", "")
GITHUB_OWNER = os.getenv("GITHUB_OWNER", "")
GITHUB_OWNER_TYPE = os.getenv("GITHUB_OWNER_TYPE", "user")  # 'user' o 'org'


class GithubError(Exception):
    pass


def _gh_headers():
    if not GITHUB_TOKEN:
        raise GithubError("Falta GITHUB_TOKEN en .env")
    return {
        "Authorization": f"Bearer {GITHUB_TOKEN}",
        "Accept": "application/vnd.github+json",
    }


def slugify(nombre: str) -> str:
    s = nombre.strip().lower()
    s = re.sub(r"[^a-z0-9]+", "-", s)
    s = re.sub(r"-+", "-", s)
    return s.strip("-")


def create_repo_for_concurso(nombre_concurso: str, privado: bool = True, descripcion: str | None = None) -> str:
    """
    Crea un repositorio en GitHub para el concurso y retorna su URL HTML.
    Si ya existe, retorna la URL del existente.
    Requiere GITHUB_TOKEN y GITHUB_OWNER en .env.
    """
    owner, owner_type = _resolve_owner_and_type()

    repo_name = slugify(nombre_concurso)
    if not repo_name:
        raise GithubError("Nombre de concurso inválido para repo")

    if owner_type == "org":
        create_url = f"https://api.github.com/orgs/{owner}/repos"
    else:
        create_url = "https://api.github.com/user/repos"

    body = {
        "name": repo_name,
        "private": privado,
        "description": (descripcion or f"Repositorio del concurso {nombre_concurso}"),
        "auto_init": True,  # crea README inicial
    }
    r = requests.post(create_url, json=body, headers=_gh_headers(), timeout=30)
    if r.status_code in (201, 202):
        return r.json().get("html_url") or r.json().get("url")

    # Si ya existe, devolver su URL
    if r.status_code == 422:  # Unprocessable Entity (posible nombre ya usado)
        check_url = f"https://api.github.com/repos/{owner}/{repo_name}"
        rc = requests.get(check_url, headers=_gh_headers(), timeout=20)
        if rc.status_code == 200:
            return rc.json().get("html_url") or rc.json().get("url")

    raise GithubError(f"Error creando repo: {r.status_code} {r.text}")


def create_file(owner: str, repo: str, path: str, content: str, mensaje: str = "add file") -> bool:
    """Crea o reemplaza un archivo en el repositorio especificado."""
    url = f"https://api.github.com/repos/{owner}/{repo}/contents/{path}"
    data = {
        "message": mensaje,
        "content": base64.b64encode(content.encode("utf-8")).decode("ascii"),
    }
    r = requests.put(url, json=data, headers=_gh_headers(), timeout=30)
    return r.status_code in (200, 201)


def _resolve_owner_and_type() -> tuple[str, str]:
    """Determina el owner y el tipo. Si GITHUB_OWNER no está definido,
    intenta obtener el login del usuario del token y usa tipo 'user'."""
    if GITHUB_OWNER:
        return GITHUB_OWNER, GITHUB_OWNER_TYPE or "user"
    # Intentar leer el usuario desde el token
    r = requests.get("https://api.github.com/user", headers=_gh_headers(), timeout=20)
    if r.status_code == 200:
        login = r.json().get("login") or ""
        if login:
            return login, "user"
    raise GithubError("No se pudo resolver el owner de GitHub; define GITHUB_OWNER en .env")