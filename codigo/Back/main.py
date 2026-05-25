import logging

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from auth.presentation.router import router as auth_router
from candidaturas.presentation.router import router as candidaturas_router
from core.migrations import upgrade_head
from demandas.presentation.router import router as demandas_router
from mom.dependencies import shutdown_event_publisher
from notificacoes.presentation.router import router as notificacoes_router
from prestadores.presentation.router import router as prestadores_router
from usuarios.presentation.router import router as usuarios_router

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(name)s %(message)s",
)

app = FastAPI(title="FieldFlow API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.on_event("startup")
def on_startup() -> None:
    upgrade_head()


@app.on_event("shutdown")
def on_shutdown() -> None:
    shutdown_event_publisher()


@app.get("/health")
def health_check():
    return {"status": "ok"}


app.include_router(auth_router)
app.include_router(demandas_router)
app.include_router(usuarios_router)
app.include_router(prestadores_router)
app.include_router(candidaturas_router)
app.include_router(notificacoes_router)
