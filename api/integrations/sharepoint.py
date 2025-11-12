import os
import requests
from dotenv import load_dotenv

from .onedrive import OneDriveError, get_access_token

load_dotenv()

GRAPH_BASE = "https://graph.microsoft.com/v1.0"

SITE_ID = os.getenv("SHAREPOINT_SITE_ID", "")
DRIVE_ID = os.getenv("SHAREPOINT_DRIVE_ID", "")
BASE_FOLDER = os.getenv("SHAREPOINT_BASE_FOLDER", "proyectos")
SHARE_TYPE = os.getenv("ONEDRIVE_SHARE_TYPE", "view")
SHARE_SCOPE = os.getenv("ONEDRIVE_SHARE_SCOPE", "organization")


def _auth_headers(token: str):
    return {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}


def ensure_folder_chain_spo(token: str, segments: list[str]) -> str:
    if not (SITE_ID and DRIVE_ID):
        raise OneDriveError("SHAREPOINT_SITE_ID/DRIVE_ID faltan en .env")

    parent_id = "root"
    path_prefix = ""
    for seg in segments:
        path_prefix = f"{path_prefix}/{seg}" if path_prefix else seg
        url = f"{GRAPH_BASE}/sites/{SITE_ID}/drives/{DRIVE_ID}/root:/{path_prefix}"
        r = requests.get(url, headers={"Authorization": f"Bearer {token}"}, timeout=15)
        if r.status_code == 200:
            parent_id = r.json()["id"]
            continue
        if r.status_code not in (404,):
            raise OneDriveError(
                f"No se pudo consultar carpeta SPO '{path_prefix}': {r.status_code} {r.text}"
            )
        # Crear carpeta bajo padre
        create_url = (
            f"{GRAPH_BASE}/sites/{SITE_ID}/drives/{DRIVE_ID}/items/{parent_id}/children"
            if parent_id != "root"
            else f"{GRAPH_BASE}/sites/{SITE_ID}/drives/{DRIVE_ID}/root/children"
        )
        body = {"name": seg, "folder": {}, "@microsoft.graph.conflictBehavior": "rename"}
        r2 = requests.post(create_url, json=body, headers=_auth_headers(token), timeout=15)
        if r2.status_code not in (200, 201):
            raise OneDriveError(
                f"No se pudo crear carpeta SPO '{path_prefix}': {r2.status_code} {r2.text}"
            )
        parent_id = r2.json()["id"]
    return parent_id


def upload_large_file_spo(token: str, folder_path: str, file_name: str, file_obj) -> dict:
    session_url = f"{GRAPH_BASE}/sites/{SITE_ID}/drives/{DRIVE_ID}/root:/{folder_path}/{file_name}:/createUploadSession"
    body = {"item": {"@microsoft.graph.conflictBehavior": "replace"}}
    r = requests.post(session_url, json=body, headers=_auth_headers(token), timeout=20)
    if r.status_code not in (200, 201):
        raise OneDriveError(f"No se pudo crear upload session SPO: {r.status_code} {r.text}")
    upload_url = r.json()["uploadUrl"]

    try:
        file_obj.seek(0, 2)
        total_size = file_obj.tell()
        file_obj.seek(0)
    except Exception:
        data_all = file_obj.read()
        total_size = len(data_all)
        from io import BytesIO
        file_obj = BytesIO(data_all)

    chunk_size = 8 * 1024 * 1024
    uploaded = 0
    while uploaded < total_size:
        chunk = file_obj.read(min(chunk_size, total_size - uploaded))
        start = uploaded
        end = uploaded + len(chunk) - 1
        headers = {
            "Content-Length": str(len(chunk)),
            "Content-Range": f"bytes {start}-{end}/{total_size}",
        }
        resp = requests.put(upload_url, data=chunk, headers=headers, timeout=60)
        if resp.status_code not in (200, 201, 202):
            raise OneDriveError(
                f"Error subiendo chunk SPO {start}-{end}: {resp.status_code} {resp.text}"
            )
        uploaded = end + 1

    item_resp = requests.get(
        f"{GRAPH_BASE}/sites/{SITE_ID}/drives/{DRIVE_ID}/root:/{folder_path}/{file_name}",
        headers={"Authorization": f"Bearer {token}"},
        timeout=15,
    )
    if item_resp.status_code != 200:
        raise OneDriveError(
            f"No se pudo recuperar archivo SPO: {item_resp.status_code} {item_resp.text}"
        )
    return item_resp.json()


def create_share_link_spo(token: str, item_id: str, share_type: str | None = None, share_scope: str | None = None) -> str:
    url = f"{GRAPH_BASE}/sites/{SITE_ID}/drives/{DRIVE_ID}/items/{item_id}/createLink"
    body = {"type": (share_type or SHARE_TYPE), "scope": (share_scope or SHARE_SCOPE)}
    r = requests.post(url, json=body, headers=_auth_headers(token), timeout=15)
    if r.status_code not in (200, 201):
        raise OneDriveError(
            f"No se pudo crear link SPO: {r.status_code} {r.text}"
        )
    data = r.json()
    return data.get("link", {}).get("webUrl") or data.get("webUrl")


def upload_text_file_spo(token: str, folder_path: str, file_name: str, content: str) -> dict:
    """
    Sube un archivo de texto pequeño directamente (sin upload session) a la carpeta indicada.
    """
    put_url = f"{GRAPH_BASE}/sites/{SITE_ID}/drives/{DRIVE_ID}/root:/{folder_path}/{file_name}:/content"
    r = requests.put(put_url, data=content.encode("utf-8"), headers={"Authorization": f"Bearer {token}"}, timeout=20)
    if r.status_code not in (200, 201):
        raise OneDriveError(f"No se pudo subir archivo de texto '{file_name}': {r.status_code} {r.text}")
    return r.json()


def create_folder_and_share_spo(
    concurso_id: int,
    categoria_id: int,
    estudiante_id: int,
    titulo: str,
    github_url: str | None = None,
    share_type: str = "edit",
) -> str:
    """
    Crea la ruta de carpetas del proyecto (incluyendo una carpeta por título) y retorna
    un enlace compartido editable a esa carpeta para que el estudiante suba sus archivos.
    Si se proporciona github_url, se guarda en un archivo 'github.txt' dentro de la carpeta.
    """
    token = get_access_token()
    base = BASE_FOLDER.strip("/")
    safe_title = titulo.strip().replace(" ", "_")
    path_segments = [
        base,
        f"concurso_{concurso_id}",
        f"categoria_{categoria_id}",
        f"estudiante_{estudiante_id}",
        safe_title,
    ]
    folder_id = ensure_folder_chain_spo(token, path_segments)
    folder_path = "/".join(path_segments)

    # Opcional: guardar el enlace de GitHub en un txt
    if github_url and github_url.strip():
        try:
            upload_text_file_spo(token, folder_path, "github.txt", github_url.strip())
        except Exception:
            # No bloquear por fallos al escribir el txt
            pass

    link = create_share_link_spo(token, folder_id, share_type=share_type, share_scope=SHARE_SCOPE)
    return link


def upload_zip_and_share_spo(concurso_id: int, categoria_id: int, estudiante_id: int, titulo: str, zip_file) -> str:
    token = get_access_token()
    base = BASE_FOLDER.strip("/")
    path_segments = [
        base,
        f"concurso_{concurso_id}",
        f"categoria_{categoria_id}",
        f"estudiante_{estudiante_id}",
    ]
    ensure_folder_chain_spo(token, path_segments)
    folder_path = "/".join(path_segments)
    safe_name = f"{titulo.strip().replace(' ', '_')}.zip"
    real_file_obj = zip_file.file if hasattr(zip_file, "file") else zip_file
    item = upload_large_file_spo(token, folder_path, safe_name, real_file_obj)
    link = create_share_link_spo(token, item["id"])
    return link