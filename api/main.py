from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

# Routers
from routers.auth_admin import router as admin_auth_router
from routers.auth_estudiantes import router as estudiantes_auth_router
from routers.concursos import router as concursos_router
from routers.categorias import router as categorias_router
from routers.proyectos import router as proyectos_router

app = FastAPI(title="EPIS Proyectos API", version="0.1.0")

# CORS (ajusta origins según despliegue)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/health")
def health():
    return {"status": "ok"}

# Registrar routers
app.include_router(admin_auth_router, prefix="/admin/auth", tags=["admin-auth"])
app.include_router(estudiantes_auth_router, prefix="/estudiantes/auth", tags=["estudiantes-auth"])
app.include_router(concursos_router, prefix="/concursos", tags=["concursos"])
app.include_router(categorias_router, prefix="/categorias", tags=["categorias"])
app.include_router(proyectos_router, prefix="/proyectos", tags=["proyectos"])