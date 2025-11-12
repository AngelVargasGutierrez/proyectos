import os
from fastapi import APIRouter, HTTPException, UploadFile, File, Form
from typing import List, Dict

from db import query, insert, execute
from schemas import ProyectoCreateRequest, ProyectoResponse, ProyectoEstadoUpdateRequest
from integrations.onedrive import upload_zip_and_share, OneDriveError
from integrations.sharepoint import upload_zip_and_share_spo, create_folder_and_share_spo
from integrations.local_sync import create_folder_and_write_local, LocalSyncError

router = APIRouter()

@router.post("/", response_model=Dict[str, int])
def crear_proyecto(payload: ProyectoCreateRequest):
    proyecto_id = insert(
        """
        INSERT INTO proyectos(titulo, github_url, zip_url, estudiante_id, concurso_id, categoria_id, fecha_envio, estado)
        VALUES(%s, %s, %s, %s, %s, %s, NOW(), 'enviado')
        """,
        (
            payload.titulo.strip(),
            payload.github_url.strip(),
            (payload.zip_url.strip() if payload.zip_url else None),
            payload.estudiante_id,
            payload.concurso_id,
            payload.categoria_id,
        ),
    )
    return {"id": proyecto_id}


@router.post("/upload", response_model=Dict[str, int])
def crear_proyecto_con_archivo(
    titulo: str = Form(...),
    github_url: str = Form(...),
    estudiante_id: int = Form(...),
    concurso_id: int = Form(...),
    categoria_id: int = Form(...),
    zip_file: UploadFile = File(...),
):
    """
    Crea un proyecto subiendo el ZIP a OneDrive automáticamente y guardando
    el enlace resultante como `zip_url`.
    """
    target = os.getenv("GRAPH_TARGET", "onedrive").lower()
    try:
        if target == "sharepoint":
            link = upload_zip_and_share_spo(
                concurso_id=concurso_id,
                categoria_id=categoria_id,
                estudiante_id=estudiante_id,
                titulo=titulo,
                zip_file=zip_file,
            )
        else:
            link = upload_zip_and_share(
                concurso_id=concurso_id,
                categoria_id=categoria_id,
                estudiante_id=estudiante_id,
                titulo=titulo,
                zip_file=zip_file,
            )
    except OneDriveError as e:
        raise HTTPException(status_code=500, detail=f"Error OneDrive: {e}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error inesperado: {e}")

    proyecto_id = insert(
        """
        INSERT INTO proyectos(titulo, github_url, zip_url, estudiante_id, concurso_id, categoria_id, fecha_envio, estado)
        VALUES(%s, %s, %s, %s, %s, %s, NOW(), 'enviado')
        """,
        (
            titulo.strip(),
            github_url.strip(),
            link,
            estudiante_id,
            concurso_id,
            categoria_id,
        ),
    )
    return {"id": proyecto_id}


@router.post("/crear_carpeta", response_model=Dict[str, int])
def crear_proyecto_con_carpeta(
    titulo: str = Form(...),
    github_url: str = Form(...),
    estudiante_id: int = Form(...),
    concurso_id: int = Form(...),
    categoria_id: int = Form(...),
):
    """
    Crea solo la carpeta del proyecto en Graph y genera un enlace compartido
    (editable) para que el estudiante suba su ZIP/RAR manualmente.
    Guarda el enlace como `zip_url` y opcionalmente un `github.txt` dentro de la carpeta.
    """
    target = os.getenv("GRAPH_TARGET", "onedrive").lower()
    try:
        if target == "sharepoint":
            link = create_folder_and_share_spo(
                concurso_id=concurso_id,
                categoria_id=categoria_id,
                estudiante_id=estudiante_id,
                titulo=titulo,
                github_url=github_url,
            )
        elif target in ("local", "local_sync", "filesystem"):
            # En modo local, retornamos la ruta local como "link"
            link = create_folder_and_write_local(
                concurso_id=concurso_id,
                categoria_id=categoria_id,
                estudiante_id=estudiante_id,
                titulo=titulo,
                github_url=github_url,
            )
        else:
            raise HTTPException(status_code=400, detail="Creación de carpeta solo implementada para SharePoint o modo local")
    except OneDriveError as e:
        raise HTTPException(status_code=500, detail=f"Error OneDrive: {e}")
    except LocalSyncError as e:
        raise HTTPException(status_code=500, detail=f"Error modo local: {e}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error inesperado: {e}")

    proyecto_id = insert(
        """
        INSERT INTO proyectos(titulo, github_url, zip_url, estudiante_id, concurso_id, categoria_id, fecha_envio, estado)
        VALUES(%s, %s, %s, %s, %s, %s, NOW(), 'enviado')
        """,
        (
            titulo.strip(),
            github_url.strip(),
            link,
            estudiante_id,
            concurso_id,
            categoria_id,
        ),
    )
    return {"id": proyecto_id}

@router.get("/por_concurso/{concurso_id}", response_model=List[ProyectoResponse])
def listar_por_concurso(concurso_id: int):
    rows = query(
        """
        SELECT p.id, p.titulo, p.github_url, p.zip_url, p.estudiante_id, p.concurso_id, p.categoria_id,
               p.fecha_envio, p.estado, p.puntuacion, p.comentarios,
               e.nombres AS estudiante_nombres, e.apellidos AS estudiante_apellidos, e.correo AS estudiante_correo,
               c.nombre AS categoria_nombre
        FROM proyectos p
        JOIN estudiantes e ON e.id = p.estudiante_id
        LEFT JOIN categorias c ON c.id = p.categoria_id
        WHERE p.concurso_id=%s
        ORDER BY p.fecha_envio DESC, p.id DESC
        """,
        (concurso_id,),
    )
    return rows

@router.get("/por_categoria/{categoria_id}", response_model=List[ProyectoResponse])
def listar_por_categoria(categoria_id: int):
    rows = query(
        """
        SELECT p.id, p.titulo, p.github_url, p.zip_url, p.estudiante_id, p.concurso_id, p.categoria_id,
               p.fecha_envio, p.estado, p.puntuacion, p.comentarios,
               e.nombres AS estudiante_nombres, e.apellidos AS estudiante_apellidos, e.correo AS estudiante_correo,
               c.nombre AS categoria_nombre
        FROM proyectos p
        JOIN estudiantes e ON e.id = p.estudiante_id
        LEFT JOIN categorias c ON c.id = p.categoria_id
        WHERE p.categoria_id=%s
        ORDER BY p.fecha_envio DESC, p.id DESC
        """,
        (categoria_id,),
    )
    return rows

@router.get("/estudiante/{estudiante_id}", response_model=List[ProyectoResponse])
def listar_por_estudiante(estudiante_id: int):
    rows = query(
        """
        SELECT p.id, p.titulo, p.github_url, p.zip_url, p.estudiante_id, p.concurso_id, p.categoria_id,
               p.fecha_envio, p.estado, p.puntuacion, p.comentarios,
               c.nombre AS categoria_nombre
        FROM proyectos p
        LEFT JOIN categorias c ON c.id = p.categoria_id
        WHERE p.estudiante_id=%s
        ORDER BY p.fecha_envio DESC, p.id DESC
        """,
        (estudiante_id,),
    )
    return rows

@router.patch("/{proyecto_id}/estado", response_model=Dict[str, int])
def actualizar_estado(proyecto_id: int, payload: ProyectoEstadoUpdateRequest):
    campos = []
    valores = []
    if payload.estado is not None:
        campos.append("estado=%s")
        valores.append(payload.estado)
    if payload.comentarios is not None:
        campos.append("comentarios=%s")
        valores.append(payload.comentarios)
    if payload.puntuacion is not None:
        campos.append("puntuacion=%s")
        valores.append(payload.puntuacion)

    if not campos:
        raise HTTPException(status_code=400, detail="Nada que actualizar")

    valores.append(proyecto_id)
    sql = f"UPDATE proyectos SET {', '.join(campos)} WHERE id=%s"
    affected = execute(sql, tuple(valores))
    if affected == 0:
        raise HTTPException(status_code=404, detail="Proyecto no encontrado")
    return {"updated": affected}