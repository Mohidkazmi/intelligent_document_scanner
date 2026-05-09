from typing import Any, List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.api import deps
from app.database.session import get_db
from app.models.document import Document
from app.cv.edge_detection import detect_document_corners

router = APIRouter()

@router.post("/detect-edges/{document_id}")
async def detect_edges(
    *,
    db: Session = Depends(get_db),
    current_user = Depends(deps.get_current_user),
    document_id: int,
) -> Any:
    """
    Detect document edges and return 4 corner coordinates.
    """
    document = db.query(Document).filter(Document.id == document_id, Document.user_id == current_user.id).first()
    if not document:
        raise HTTPException(status_code=404, detail="Document not found")
    
    try:
        corners = detect_document_corners(document.original_path)
        return {
            "document_id": document_id,
            "corners": [
                {"x": float(c[0]), "y": float(c[1])} for c in corners
            ]
        }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Edge detection failed: {e}"
        )
