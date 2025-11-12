from fastapi import APIRouter, HTTPException
from typing import Dict
import hashlib

from db import query, insert
from schemas import AdminLoginRequest, AdminRegisterRequest, AdminResponse

router = APIRouter()

@router.post("/login", response_model=AdminResponse)
def login_admin(payload: AdminLoginRequest):
    correo = payload.correo.strip().lower()
    contrasena = payload.contrasena.strip()
    rows = query(
        """
        SELECT id, nombres, apellidos, correo, numero_telefono
        FROM administradores
        WHERE correo=%s AND contrasena_hash=SHA2(%s, 256)
        LIMIT 1
        """,
        (correo, contrasena),
    )
    if not rows:
        raise HTTPException(status_code=401, detail="Credenciales incorrectas")
    return rows[0]

# Nuevo: obtener administrador por correo (para login vía Firebase)
@router.get("/by_email/{correo}", response_model=AdminResponse)
def obtener_admin_por_correo(correo: str):
    correo_n = correo.strip().lower()
    rows = query(
        """
        SELECT id, nombres, apellidos, correo, numero_telefono
        FROM administradores
        WHERE correo=%s
        LIMIT 1
        """,
        (correo_n,),
    )
    if not rows:
        raise HTTPException(status_code=404, detail="Administrador no encontrado")
    return rows[0]

@router.post("/register", response_model=Dict[str, int])
def register_admin(payload: AdminRegisterRequest):
    correo = payload.correo.strip().lower()
    # Evitar duplicados
    existing = query("SELECT id FROM administradores WHERE correo=%s LIMIT 1", (correo,))
    if existing:
        raise HTTPException(status_code=409, detail="El correo ya existe")

    admin_id = insert(
        """
        INSERT INTO administradores(nombres, apellidos, correo, numero_telefono, contrasena_hash, fecha_creacion)
        VALUES(%s, %s, %s, %s, SHA2(%s,256), NOW())
        """,
        (
            payload.nombres.strip(),
            payload.apellidos.strip(),
            correo,
            payload.numero_telefono.strip(),
            payload.contrasena.strip(),
        ),
    )
    return {"id": admin_id}