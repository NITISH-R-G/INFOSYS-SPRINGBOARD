"""
Intake Router — Email-to-AI and Dealer Forward Endpoints
Blueprint for bypassing manual PDF uploads.
"""
import os
import uuid
import logging
from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form
from pydantic import BaseModel, EmailStr
from typing import Optional, List
from sqlalchemy.orm import Session

from ..database import get_db, Contract, ContractFile, User
from ..services.auth_service import get_current_active_user
from ..config import settings
from ..exceptions import ValidationError

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/intake", tags=["Intake"])


class EmailWebhookPayload(BaseModel):
    """Payload from an email forwarding webhook (e.g., SendGrid Inbound Parse)"""
    sender_email: str
    subject: Optional[str] = None
    body_text: Optional[str] = None
    # Attachments would be handled as files in the form data


class DealerForwardPayload(BaseModel):
    """Payload for dealer-shared document link"""
    dealer_name: Optional[str] = None
    document_url: Optional[str] = None
    notes: Optional[str] = None


@router.post("/email-webhook")
async def email_webhook(
    sender_email: str = Form(...),
    subject: str = Form(default=""),
    body_text: str = Form(default=""),
    attachments: List[UploadFile] = File(default=[]),
    db: Session = Depends(get_db),
):
    """
    Receive forwarded emails with PDF attachments.
    
    This endpoint is designed to be called by an email forwarding service
    (e.g., SendGrid Inbound Parse, Mailgun Routes, AWS SES).
    
    It creates a contract record and enqueues processing for each PDF attachment.
    
    NOTE: In production, this should be secured with a webhook secret/signature.
    """
    if not attachments:
        raise ValidationError(detail="No attachments found in the email.")

    # Look up user by sender email
    user = db.query(User).filter(User.email == sender_email).first()
    if not user:
        logger.warning(f"Email webhook from unknown sender: {sender_email}")
        # In production, could auto-create a user or send a registration link
        raise ValidationError(
            detail="Sender email not registered. Please sign up first."
        )

    created_contracts = []

    for attachment in attachments:
        ext = os.path.splitext(attachment.filename)[1].lower()
        if ext not in settings.ALLOWED_EXTENSIONS:
            logger.info(f"Skipping non-document attachment: {attachment.filename}")
            continue

        contents = await attachment.read()

        # Save file
        os.makedirs(settings.UPLOAD_DIR, exist_ok=True)
        file_id = str(uuid.uuid4())
        file_path = os.path.join(settings.UPLOAD_DIR, f"{file_id}{ext}")

        with open(file_path, "wb") as f:
            f.write(contents)

        # Create contract
        db_contract = Contract(
            user_id=user.id,
            status="queued",
        )
        db.add(db_contract)
        db.flush()

        # Create contract file
        db_file = ContractFile(
            contract_id=db_contract.id,
            filename=attachment.filename,
            file_path=file_path,
            file_type="pdf" if ext == ".pdf" else "image",
            file_size_bytes=len(contents)
        )
        db.add(db_file)

        # Enqueue background task (if Celery is available)
        job_id = None
        try:
            from ..tasks import process_contract_task
            task = process_contract_task.delay(db_contract.id, file_path)
            job_id = task.id
            db_contract.job_id = job_id
        except Exception as e:
            logger.warning(f"Could not enqueue task (Celery may not be running): {e}")
            db_contract.status = "pending"

        created_contracts.append({
            "contract_id": db_contract.id,
            "filename": attachment.filename,
            "job_id": job_id,
            "status": db_contract.status
        })

    db.commit()

    return {
        "message": f"Processed {len(created_contracts)} document(s) from email.",
        "sender": sender_email,
        "contracts": created_contracts
    }


@router.post("/dealer-forward")
async def dealer_forward(
    payload: DealerForwardPayload,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """
    Accept a dealer-shared document link for processing.
    
    In a full implementation, this would:
    1. Fetch the document from the dealer's URL
    2. Save it locally
    3. Create a contract record
    4. Enqueue processing
    
    Currently returns a blueprint response.
    """
    return {
        "message": "Dealer forward received. Document processing will begin shortly.",
        "dealer_name": payload.dealer_name,
        "document_url": payload.document_url,
        "status": "blueprint",
        "note": "Full implementation requires document fetching from dealer systems."
    }
