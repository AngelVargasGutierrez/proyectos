from fastapi import APIRouter, HTTPException
from typing import Dict

from db import query, insert
from schemas import EstudianteLoginRequest, EstudianteRegisterRequest, EstudianteResponse

router = APIRouter()

@router.post("/login", response_model=EstudianteResponse)
def login_estudiante(payload: EstudianteLoginRequest):
    correo = payload.correo.strip().lower()
    contrasena = payload.contrasena.strip()
    rows = query(
        """
        SELECT id, nombres, apellidos, correo, numero_telefono
        FROM estudiantes
        WHERE correo=%s AND contrasena_hash=SHA2(%s, 256)
        LIMIT 1
        """,
        (correo, contrasena),
    )
    if not rows:
        raise HTTPException(status_code=401, detail="Credenciales incorrectas")
    return rows[0]

# Nuevo: obtener estudiante por correo (para login vía Firebase)
@router.get("/by_email/{correo}", response_model=EstudianteResponse)
def obtener_estudiante_por_correo(correo: str):
    correo_n = correo.strip().lower()
    rows = query(
        """
        SELECT id, nombres, apellidos, correo, numero_telefono
        FROM estudiantes
        WHERE correo=%s
        LIMIT 1
        """,
        (correo_n,),
    )
    if not rows:
        raise HTTPException(status_code=404, detail="Estudiante no encontrado")
    return rows[0]

@router.post("/register", response_model=Dict[str, int])
def register_estudiante(payload: EstudianteRegisterRequest):
    correo = payload.correo.strip().lower()
    existing = query("SELECT id FROM estudiantes WHERE correo=%s LIMIT 1", (correo,))
    if existing:
        raise HTTPException(status_code=409, detail="El correo ya existe")

    estudiante_id = insert(
        """
        INSERT INTO estudiantes(nombres, apellidos, codigo_universitario, correo, numero_telefono, ciclo, contrasena_hash, fecha_creacion)
        VALUES(%s, %s, %s, %s, %s, %s, SHA2(%s,256), NOW())
        """,
        (
            payload.nombres.strip(),
            payload.apellidos.strip(),
            payload.codigo_universitario.strip(),
            correo,
            payload.numero_telefono.strip(),
            payload.ciclo,
            payload.contrasena.strip(),
        ),
    )
    return {"id": estudiante_id}