from fastapi import APIRouter
from app.api.api_v1.endpoints import auth, documents, scanner

api_router = APIRouter()
api_router.include_router(auth.router, prefix="/auth", tags=["auth"])
api_router.include_router(documents.router, prefix="/documents", tags=["documents"])
api_router.include_router(scanner.router, prefix="/scanner", tags=["scanner"])
