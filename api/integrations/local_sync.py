import os
from dotenv import load_dotenv

load_dotenv()


class LocalSyncError(Exception):
    pass


SYNC_ROOT = os.getenv("SYNC_ONEDRIVE_PATH", "").rstrip("/\\")


def _ensure_folder_chain_local(segments: list[str]) -> str:
    if not SYNC_ROOT:
        raise LocalSyncError("SYNC_ONEDRIVE_PATH falta en .env para modo local")
    path = SYNC_ROOT
    for seg in segments:
        path = os.path.join(path, seg)
        # Crear si no existe
        os.makedirs(path, exist_ok=True)
    return path


def create_folder_and_write_local(
    concurso_id: int,
    categoria_id: int,
    estudiante_id: int,
    titulo: str,
    github_url: str | None = None,
) -> str:
    """
    Crea la carpeta del proyecto en el directorio sincronizado local
    (OneDrive/SharePoint client) y opcionalmente escribe github.txt.
    Retorna la ruta local creada.
    """
    safe_title = titulo.strip().replace(" ", "_")
    segments = [
        f"concurso_{concurso_id}",
        f"categoria_{categoria_id}",
        f"estudiante_{estudiante_id}",
        safe_title,
    ]
    folder_path = _ensure_folder_chain_local(segments)

    if github_url and github_url.strip():
        try:
            txt_path = os.path.join(folder_path, "github.txt")
            with open(txt_path, "w", encoding="utf-8") as f:
                f.write(github_url.strip())
        except Exception as e:
            # No bloquear por fallo al escribir el txt
            pass

    return folder_path