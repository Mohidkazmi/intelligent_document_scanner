import os
import uuid
import shutil
from typing import Any, List
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, status
from sqlalchemy.orm import Session

from app.api import deps
from app.database.session import get_db
from app.models.document import Document
from app.schemas.document import Document as DocumentSchema
from app.core.config import settings

router = APIRouter()

SUPPORTED_FORMATS = ["image/jpeg", "image/png", "image/webp", "application/pdf", "image/tiff"]
MAX_FILE_SIZE = 20 * 1024 * 1024  # 20MB

@router.post("/upload", response_model=DocumentSchema)
async def upload_document(
    *,
    db: Session = Depends(get_db),
    current_user = Depends(deps.get_current_user),
    file: UploadFile = File(...),
) -> Any:
    """
    Upload a document.
    """
    # Validate content type
    if file.content_type not in SUPPORTED_FORMATS:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"File type {file.content_type} not supported. Supported types: {', '.join(SUPPORTED_FORMATS)}"
        )

    # Validate file size (rough check using file header if possible, or after reading)
    # Note: UploadFile.size is available in newer FastAPI versions
    file.file.seek(0, os.SEEK_END)
    file_size = file.file.tell()
    file.file.seek(0)
    
    if file_size > MAX_FILE_SIZE:
        raise HTTPException(
            status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
            detail=f"File size exceeds 20MB limit."
        )

    # Generate unique filename
    file_ext = os.path.splitext(file.filename)[1]
    unique_filename = f"{uuid.uuid4()}{file_ext}"
    file_path = os.path.join(settings.UPLOAD_DIR, unique_filename)

    # Save file
    try:
        with open(file_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Could not save file: {e}"
        )

    # Create DB entry
    db_obj = Document(
        user_id=current_user.id,
        filename=file.filename,
        mime_type=file.content_type,
        original_path=file_path,
        status="uploaded"
    )
    db.add(db_obj)
    db.commit()
    db.refresh(db_obj)
    
    return db_obj

@router.get("/{id}", response_model=DocumentSchema)
def get_document(
    *,
    db: Session = Depends(get_db),
    current_user = Depends(deps.get_current_user),
    id: int,
) -> Any:
    """
    Get document by ID.
    """
    document = db.query(Document).filter(Document.id == id, Document.user_id == current_user.id).first()
    if not document:
        raise HTTPException(status_code=404, detail="Document not found")
    return document

@router.delete("/{id}", response_model=DocumentSchema)
def delete_document(
    *,
    db: Session = Depends(get_db),
    current_user = Depends(deps.get_current_user),
    id: int,
) -> Any:
    """
    Delete a document.
    """
    document = db.query(Document).filter(Document.id == id, Document.user_id == current_user.id).first()
    if not document:
        raise HTTPException(status_code=404, detail="Document not found")
    
    # Remove physical file
    if os.path.exists(document.original_path):
        os.remove(document.original_path)
    if document.processed_path and os.path.exists(document.processed_path):
        os.remove(document.processed_path)
        
    db.delete(document)
    db.commit()
    return document
