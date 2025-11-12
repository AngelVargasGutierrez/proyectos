from typing import Optional, List
from pydantic import BaseModel
from datetime import datetime

class AdminLoginRequest(BaseModel):
    correo: str
    contrasena: str

class AdminRegisterRequest(BaseModel):
    nombres: str
    apellidos: str
    correo: str
    numero_telefono: str
    contrasena: str

class AdminResponse(BaseModel):
    id: int
    nombres: str
    apellidos: str
    correo: str
    numero_telefono: str

class EstudianteLoginRequest(BaseModel):
    correo: str
    contrasena: str

class EstudianteRegisterRequest(BaseModel):
    nombres: str
    apellidos: str
    codigo_universitario: str
    correo: str
    numero_telefono: str
    ciclo: int
    contrasena: str

class EstudianteResponse(BaseModel):
    id: int
    nombres: str
    apellidos: str
    correo: str
    numero_telefono: str
    ciclo: int

class ConcursoCreateRequest(BaseModel):
    nombre: str
    administrador_id: int
    fecha_limite_inscripcion: Optional[str] = None
    fecha_revision: Optional[str] = None
    fecha_confirmacion_aceptados: Optional[str] = None

class ConcursoUpdateRequest(BaseModel):
    nombre: Optional[str] = None
    fecha_limite_inscripcion: Optional[str] = None
    fecha_revision: Optional[str] = None
    fecha_confirmacion_aceptados: Optional[str] = None

class ConcursoDbResponse(BaseModel):
    id: int
    nombre: str
    administrador_id: int
    fecha_limite_inscripcion: Optional[datetime]
    fecha_revision: Optional[datetime]
    fecha_confirmacion_aceptados: Optional[datetime]
    fecha_creacion: Optional[datetime]

# Categorías
class CategoriaCreateRequest(BaseModel):
    nombre: str
    concurso_id: int
    rango_ciclos: Optional[str] = None

class CategoriaResponse(BaseModel):
    id: int
    nombre: str
    concurso_id: int
    rango_ciclos: Optional[str] = None

class ProyectoCreateRequest(BaseModel):
    titulo: str
    github_url: str
    zip_url: Optional[str] = None
    estudiante_id: int
    concurso_id: int
    categoria_id: int

class ProyectoResponse(BaseModel):
    id: int
    titulo: str
    github_url: str
    zip_url: Optional[str]
    estudiante_id: int
    concurso_id: int
    categoria_id: int
    fecha_envio: Optional[datetime]
    estado: Optional[str]
    puntuacion: Optional[float]
    comentarios: Optional[str]
    # Extras para vistas del admin
    estudiante_nombres: Optional[str] = None
    estudiante_apellidos: Optional[str] = None
    estudiante_correo: Optional[str] = None
    categoria_nombre: Optional[str] = None

class ProyectoEstadoUpdateRequest(BaseModel):
    estado: Optional[str] = None
    comentarios: Optional[str] = None
    puntuacion: Optional[float] = None