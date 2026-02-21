"""
Files Router
Serves uploaded contract files (PDFs/images) securely
"""
import os
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.responses import FileResponse
from sqlalchemy.orm import Session

from ..database import get_db, Contract

router = APIRouter(prefix="/files", tags=["Files"])


@router.get("/{contract_id}")
async def get_contract_file(
    contract_id: int,
    db: Session = Depends(get_db)
):
    """
    Serve the uploaded contract file (PDF or image)
    
    Returns the file with appropriate content type
    """
    # Get contract from database
    contract = db.query(Contract).filter(Contract.id == contract_id).first()
    
    if not contract:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Contract not found"
        )
    
    # Check if file exists
    if not contract.file_path or not os.path.exists(contract.file_path):
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Contract file not found on disk"
        )
    
    # Determine content type based on file extension
    ext = os.path.splitext(contract.file_path)[1].lower()
    content_types = {
        ".pdf": "application/pdf",
        ".png": "image/png",
        ".jpg": "image/jpeg",
        ".jpeg": "image/jpeg",
        ".gif": "image/gif",
        ".tiff": "image/tiff",
        ".tif": "image/tiff",
    }
    
    content_type = content_types.get(ext, "application/octet-stream")
    
    return FileResponse(
        path=contract.file_path,
        media_type=content_type,
        filename=contract.filename
    )
