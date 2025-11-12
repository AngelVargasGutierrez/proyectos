from fastapi import APIRouter, HTTPException
from typing import List, Dict

from db import query, insert, execute
from schemas import CategoriaCreateRequest, CategoriaResponse

router = APIRouter()

@router.get("/por_concurso/{concurso_id}", response_model=List[CategoriaResponse])
def listar_categorias_por_concurso(concurso_id: int):
    rows = query(
        """
        SELECT id, nombre, concurso_id, rango_ciclos
        FROM categorias
        WHERE concurso_id=%s
        ORDER BY id ASC
        """,
        (concurso_id,),
    )
    return rows

@router.post("/", response_model=Dict[str, int])
def crear_categoria(payload: CategoriaCreateRequest):
    categoria_id = insert(
        """
        INSERT INTO categorias(nombre, concurso_id, rango_ciclos)
        VALUES(%s, %s, %s)
        """,
        (
            payload.nombre.strip(),
            payload.concurso_id,
            (payload.rango_ciclos or None),
        ),
    )
    return {"id": categoria_id}

@router.delete("/por_concurso/{concurso_id}", response_model=Dict[str, int])
def eliminar_categorias_por_concurso(concurso_id: int):
    affected = execute("DELETE FROM categorias WHERE concurso_id=%s", (concurso_id,))
    return {"deleted": affected}