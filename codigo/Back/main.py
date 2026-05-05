from fastapi import FastAPI

from api.demandas import router as demandas_router
from database.database import Base, engine

app = FastAPI(title="FieldFlow API")


@app.on_event("startup")
def on_startup() -> None:
	Base.metadata.create_all(bind=engine)


@app.get("/health")
def health_check():
	return {"status": "ok"}


app.include_router(demandas_router)
