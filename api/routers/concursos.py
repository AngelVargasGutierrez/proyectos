from fastapi import APIRouter, HTTPException
from typing import Dict
from integrations.github import create_repo_for_concurso, GithubError
from typing import List, Dict

from db import query, insert, execute
from schemas import (
    ConcursoCreateRequest,
    ConcursoUpdateRequest,
    ConcursoDbResponse,
)

router = APIRouter()

@router.get("/", response_model=List[ConcursoDbResponse])
def listar_concursos():
    rows = query(
        """
        SELECT id, nombre, administrador_id,
               fecha_limite_inscripcion, fecha_revision,
               fecha_confirmacion_aceptados, fecha_creacion
        FROM concursos
        ORDER BY fecha_creacion DESC, id DESC
        """,
        (),
    )
    return rows

@router.get("/admin/{admin_id}", response_model=List[ConcursoDbResponse])
def listar_concursos_por_admin(admin_id: int):
    rows = query(
        """
        SELECT id, nombre, administrador_id,
               fecha_limite_inscripcion, fecha_revision,
               fecha_confirmacion_aceptados, fecha_creacion
        FROM concursos
        WHERE administrador_id=%s
        ORDER BY fecha_creacion DESC, id DESC
        """,
        (admin_id,),
    )
    return rows

@router.post("/", response_model=Dict[str, int])
def crear_concurso(payload: ConcursoCreateRequest):
    concurso_id = insert(
        """
        INSERT INTO concursos(
            nombre, administrador_id,
            fecha_limite_inscripcion, fecha_revision,
            fecha_confirmacion_aceptados, fecha_creacion
        )
        VALUES(%s, %s, %s, %s, %s, NOW())
        """,
        (
            payload.nombre.strip(),
            payload.administrador_id,
            payload.fecha_limite_inscripcion,
            payload.fecha_revision,
            payload.fecha_confirmacion_aceptados,
        ),
    )
    return {"id": concurso_id}


@router.post("/{concurso_id}/github_repo", response_model=Dict[str, str])
def crear_repo_github(concurso_id: int):
    rows = query("SELECT nombre FROM concursos WHERE id=%s", (concurso_id,))
    if not rows:
        raise HTTPException(status_code=404, detail="Concurso no encontrado")
    nombre = rows[0]["nombre"]
    try:
        url = create_repo_for_concurso(nombre, privado=True)
    except GithubError as e:
        raise HTTPException(status_code=500, detail=f"Error GitHub: {e}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error inesperado: {e}")
    return {"repo_url": url}

@router.patch("/{concurso_id}", response_model=Dict[str, int])
def actualizar_concurso(concurso_id: int, payload: ConcursoUpdateRequest):
    campos = []
    valores = []
    if payload.nombre is not None:
        campos.append("nombre=%s")
        valores.append(payload.nombre.strip())
    if payload.fecha_limite_inscripcion is not None:
        campos.append("fecha_limite_inscripcion=%s")
        valores.append(payload.fecha_limite_inscripcion)
    if payload.fecha_revision is not None:
        campos.append("fecha_revision=%s")
        valores.append(payload.fecha_revision)
    if payload.fecha_confirmacion_aceptados is not None:
        campos.append("fecha_confirmacion_aceptados=%s")
        valores.append(payload.fecha_confirmacion_aceptados)

    if not campos:
        raise HTTPException(status_code=400, detail="Nada que actualizar")

    valores.append(concurso_id)
    sql = f"UPDATE concursos SET {', '.join(campos)} WHERE id=%s"
    affected = execute(sql, tuple(valores))
    if affected == 0:
        raise HTTPException(status_code=404, detail="Concurso no encontrado")
    return {"updated": affected}

@router.delete("/{concurso_id}", response_model=Dict[str, int])
def eliminar_concurso(concurso_id: int):
    affected = execute("DELETE FROM concursos WHERE id=%s", (concurso_id,))
    if affected == 0:
        raise HTTPException(status_code=404, detail="Concurso no encontrado")
    return {"deleted": affected}