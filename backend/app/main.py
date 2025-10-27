from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.core.config import settings
from app.core.database import init_db
from app.routers import upload, personas, historial, tasks, websocket
from contextlib import asynccontextmanager


@asynccontextmanager
async def lifespan(app: FastAPI):
    print("🚀 Iniciando aplicación...")
    await init_db()
    print("✅ Base de datos inicializada")
    yield
    print("🛑 Cerrando aplicación...")


app = FastAPI(
    title=settings.APP_NAME,
    version=settings.APP_VERSION,
    lifespan=lifespan
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins_list,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(upload.router, prefix="/api")
app.include_router(personas.router, prefix="/api")
app.include_router(historial.router, prefix="/api")
app.include_router(tasks.router, prefix="/api")
app.include_router(websocket.router, prefix="/api")


@app.get("/")
async def root():
    return {
        "nombre": settings.APP_NAME,
        "version": settings.APP_VERSION,
        "estado": "online"
    }


@app.get("/health")
async def health_check():
    return {
        "estado": "healthy",
        "servicio": settings.APP_NAME
    }
