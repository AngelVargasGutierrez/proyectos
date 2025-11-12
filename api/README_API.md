# EPIS Proyectos API (FastAPI)

API en Python que reemplaza la conexión directa desde Flutter a MySQL.

## Requisitos
- Python 3.10+
- Acceso a la base de datos MySQL `epis_proyectos`

## Configuración
1. Copia `.env` y ajusta credenciales si es necesario.
2. Crea el entorno virtual e instala dependencias:

```powershell
python -m venv venv
venv\Scripts\pip install -r requirements.txt
```

## Ejecutar

```powershell
venv\Scripts\uvicorn api.main:app --host 0.0.0.0 --port 8000 --reload
```

## Endpoints principales
- `GET /health`
- `POST /admin/auth/login`
- `POST /admin/auth/register`
- `POST /estudiantes/auth/login`
- `POST /estudiantes/auth/register`
- `GET /concursos/admin/{admin_id}`
- `POST /concursos`
- `DELETE /concursos/{concurso_id}`
- `GET /categorias/por_concurso/{concurso_id}`
- `POST /categorias`
- `POST /proyectos`
- `GET /proyectos/por_concurso/{concurso_id}`
- `GET /proyectos/por_categoria/{categoria_id}`
- `GET /proyectos/estudiante/{estudiante_id}`
- `PATCH /proyectos/{proyecto_id}/estado`

## Notas
- Hash de contraseñas: `SHA2(256)` para compatibilidad con la base de datos.
- Ajusta CORS en `api/main.py` según las apps que consuman la API.