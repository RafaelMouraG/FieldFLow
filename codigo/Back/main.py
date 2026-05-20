from fastapi import FastAPI

from core.database import Base, engine
from demandas.infrastructure.database import models as _demanda_models  # noqa: F401
from demandas.presentation.router import router as demandas_router
from mom.dependencies import shutdown_event_publisher
from usuarios.infrastructure.database import models as _usuario_models  # noqa: F401
from usuarios.presentation.router import router as usuarios_router

app = FastAPI(title="FieldFlow API")


@app.on_event("startup")
def on_startup() -> None:
    Base.metadata.create_all(bind=engine)


@app.on_event("shutdown")
def on_shutdown() -> None:
    shutdown_event_publisher()


@app.get("/health")
def health_check():
    return {"status": "ok"}


app.include_router(demandas_router)
app.include_router(usuarios_router)
