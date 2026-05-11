from fastapi import FastAPI

from core.database import Base, engine
from demandas.router import router as demandas_router

app = FastAPI(title="FieldFlow API")


@app.on_event("startup")
def on_startup() -> None:
    Base.metadata.create_all(bind=engine)


@app.get("/health")
def health_check():
    return {"status": "ok"}


app.include_router(demandas_router)
