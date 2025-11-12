import os
import requests
from dotenv import load_dotenv

load_dotenv()

GRAPH_BASE = "https://graph.microsoft.com/v1.0"

TENANT_ID = os.getenv("ONEDRIVE_TENANT_ID", "")
CLIENT_ID = os.getenv("ONEDRIVE_CLIENT_ID", "")
CLIENT_SECRET = os.getenv("ONEDRIVE_CLIENT_SECRET", "")
REFRESH_TOKEN = os.getenv("ONEDRIVE_REFRESH_TOKEN", "")
BASE_FOLDER = os.getenv("ONEDRIVE_BASE_FOLDER", "PROYECTOS")
SHARE_TYPE = os.getenv("ONEDRIVE_SHARE_TYPE", "view")
SHARE_SCOPE = os.getenv("ONEDRIVE_SHARE_SCOPE", "anonymous")


class OneDriveError(Exception):
    pass


def _headers(token: str):
    return {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}


def get_access_token() -> str:
    """
    Obtiene un access_token usando el refresh_token almacenado en .env.
    Requiere que el app en Azure AD tenga permisos Delegados a Graph y
    que el refresh token provenga de un usuario con acceso a OneDrive.
    """
    if not (TENANT_ID and CLIENT_ID and CLIENT_SECRET and REFRESH_TOKEN):
        raise OneDriveError("Variables .env de OneDrive incompletas")
    token_url = f"https://login.microsoftonline.com/{TENANT_ID}/oauth2/v2.0/token"
    data = {
        "client_id": CLIENT_ID,
        "client_secret": CLIENT_SECRET,
        "grant_type": "refresh_token",
        "refresh_token": REFRESH_TOKEN,
        "scope": "https://graph.microsoft.com/.default offline_access",
    }
    r = requests.post(token_url, data=data, timeout=20)
    if r.status_code != 200:
        raise OneDriveError(f"Error obteniendo token: {r.status_code} {r.text}")
    return r.json().get("access_token", "")


def ensure_folder_chain(token: str, segments: list[str]) -> str:
    """
    Asegura la existencia de la cadena de carpetas en OneDrive y retorna el id
    de la última carpeta.
    """
    parent_id = "root"
    path_prefix = ""
    for seg in segments:
        path_prefix = f"{path_prefix}/{seg}" if path_prefix else seg
        # Intentar obtener la carpeta por path
        url = f"{GRAPH_BASE}/me/drive/root:/{path_prefix}"
        r = requests.get(url, headers={"Authorization": f"Bearer {token}"}, timeout=15)
        if r.status_code == 200:
            parent_id = r.json()["id"]
            continue
        if r.status_code not in (404,):
            raise OneDriveError(
                f"No se pudo consultar carpeta '{path_prefix}': {r.status_code} {r.text}"
            )
        # Crear carpeta bajo el padre actual
        create_url = (
            f"{GRAPH_BASE}/me/drive/items/{parent_id}/children"
            if parent_id != "root"
            else f"{GRAPH_BASE}/me/drive/root/children"
        )
        body = {"name": seg, "folder": {}, "@microsoft.graph.conflictBehavior": "rename"}
        r2 = requests.post(create_url, json=body, headers=_headers(token), timeout=15)
        if r2.status_code not in (200, 201):
            raise OneDriveError(
                f"No se pudo crear carpeta '{path_prefix}': {r2.status_code} {r2.text}"
            )
        parent_id = r2.json()["id"]
    return parent_id


def upload_large_file(token: str, folder_path: str, file_name: str, file_obj) -> dict:
    """
    Sube un archivo grande en chunks usando un UploadSession.
    Retorna el driveItem del archivo subido.
    """
    session_url = f"{GRAPH_BASE}/me/drive/root:/{folder_path}/{file_name}:/createUploadSession"
    body = {"item": {"@microsoft.graph.conflictBehavior": "replace"}}
    r = requests.post(session_url, json=body, headers=_headers(token), timeout=20)
    if r.status_code not in (200, 201):
        raise OneDriveError(f"No se pudo crear upload session: {r.status_code} {r.text}")
    upload_url = r.json()["uploadUrl"]

    # Determinar tamaño total
    try:
        file_obj.seek(0, 2)
        total_size = file_obj.tell()
        file_obj.seek(0)
    except Exception:
        # Fallback: leer todo en memoria (no ideal, pero seguro para archivos pequeños)
        data_all = file_obj.read()
        total_size = len(data_all)
        file_obj = BytesIO(data_all)  # type: ignore

    chunk_size = 8 * 1024 * 1024  # 8MB
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
                f"Error subiendo chunk {start}-{end}: {resp.status_code} {resp.text}"
            )
        uploaded = end + 1

    # Recuperar el item subido
    item_resp = requests.get(
        f"{GRAPH_BASE}/me/drive/root:/{folder_path}/{file_name}",
        headers={"Authorization": f"Bearer {token}"},
        timeout=15,
    )
    if item_resp.status_code != 200:
        raise OneDriveError(
            f"No se pudo recuperar archivo subido: {item_resp.status_code} {item_resp.text}"
        )
    return item_resp.json()


def create_share_link(token: str, item_id: str) -> str:
    url = f"{GRAPH_BASE}/me/drive/items/{item_id}/createLink"
    body = {"type": SHARE_TYPE, "scope": SHARE_SCOPE}
    r = requests.post(url, json=body, headers=_headers(token), timeout=15)
    if r.status_code not in (200, 201):
        raise OneDriveError(
            f"No se pudo crear link compartido: {r.status_code} {r.text}"
        )
    data = r.json()
    return data.get("link", {}).get("webUrl") or data.get("webUrl")


def upload_zip_and_share(
    concurso_id: int,
    categoria_id: int,
    estudiante_id: int,
    titulo: str,
    zip_file,
) -> str:
    """
    Sube el ZIP a la ruta organizada del concurso y retorna un enlace público.
    """
    token = get_access_token()
    base = BASE_FOLDER.strip("/")

    # Estructura: BASE/concurso_<id>/categoria_<id>/estudiante_<id>
    path_segments = [
        base,
        f"concurso_{concurso_id}",
        f"categoria_{categoria_id}",
        f"estudiante_{estudiante_id}",
    ]
    ensure_folder_chain(token, path_segments)
    folder_path = "/".join(path_segments)

    safe_name = f"{titulo.strip().replace(' ', '_')}.zip"
    real_file_obj = zip_file.file if hasattr(zip_file, "file") else zip_file
    item = upload_large_file(token, folder_path, safe_name, real_file_obj)
    link = create_share_link(token, item["id"])
    return link