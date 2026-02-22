"""
Human-to-Human Messaging API Endpoints
"""
from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import or_
import logging
from jose import jwt
from datetime import datetime, timedelta

from ..database import get_db, User, Conversation, Message, Contract, Dealer
from ..config import settings
from ..models import schemas
from ..services.auth_service import get_current_active_user

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/messaging", tags=["Messaging"])


@router.get("/conversations", response_model=List[schemas.ConversationResponse])
def get_conversations(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """
    Get all conversations for the current user
    """
    conversations = db.query(Conversation).filter(
        or_(
            Conversation.buyer_id == current_user.id,
            Conversation.dealer_id == current_user.id
        )
    ).order_by(Conversation.updated_at.desc()).all()
    
    return conversations


@router.post("/conversations", response_model=schemas.ConversationResponse, status_code=status.HTTP_201_CREATED)
def create_conversation(
    request: schemas.ConversationCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """
    Create a new conversation thread (Buyer typically initiates)
    """
    # Verify the target user exists and is a dealer
    dealer = db.query(User).filter(User.id == request.dealer_id).first()
    if not dealer or dealer.role != "dealer":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Valid Dealer ID required to start conversation"
        )
    
    # Optionally verify contract access
    if request.contract_id:
        contract = db.query(Contract).filter(
            Contract.id == request.contract_id,
            Contract.user_id == current_user.id
        ).first()
        if not contract:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You do not have access to this contract"
            )
            
    conversation = Conversation(
        buyer_id=current_user.id,
        dealer_id=dealer.id,
        contract_id=request.contract_id,
        subject=request.subject or f"Inquiry with {dealer.full_name}"
    )
    db.add(conversation)
    db.commit()
    db.refresh(conversation)
    return conversation


@router.get("/conversations/{conversation_id}/messages", response_model=List[schemas.MessageResponse])
def get_messages(
    conversation_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """
    Get all messages in a specific conversation
    """
    conversation = db.query(Conversation).filter(Conversation.id == conversation_id).first()
    if not conversation:
        raise HTTPException(status_code=404, detail="Conversation not found")
        
    # Security block
    if current_user.id not in [conversation.buyer_id, conversation.dealer_id]:
        raise HTTPException(status_code=403, detail="Not authorized to view this thread")
        
    messages = db.query(Message).filter(Message.conversation_id == conversation_id).order_by(Message.created_at.asc()).all()
    
    # Mark messages as read if the current user is not the sender
    unread = [m for m in messages if m.sender_id != current_user.id and not m.is_read]
    if unread:
        for m in unread:
            m.is_read = True
        db.commit()
        
    return messages


@router.post("/conversations/{conversation_id}/messages", response_model=schemas.MessageResponse)
def post_message(
    conversation_id: int,
    message: schemas.MessageCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """
    Reply to a conversation thread
    """
    conversation = db.query(Conversation).filter(Conversation.id == conversation_id).first()
    if not conversation:
        raise HTTPException(status_code=404, detail="Conversation not found")
        
    if current_user.id not in [conversation.buyer_id, conversation.dealer_id]:
        raise HTTPException(status_code=403, detail="Not authorized to post in this thread")
        
    new_message = Message(
        conversation_id=conversation_id,
        sender_id=current_user.id,
        content=message.content
    )
    
    # Update conversation's updated_at timestamp to bubble up in the inbox
    import datetime
    conversation.updated_at = datetime.datetime.utcnow()
    
    db.add(new_message)
    
    # --- Gap 9: Magic Link Routing ---
    # Check if the recipient is an unclaimed dealer
    recipient_id = conversation.dealer_id if current_user.id == conversation.buyer_id else conversation.buyer_id
    recipient_user = db.query(User).filter(User.id == recipient_id).first()
    
    if recipient_user and recipient_user.role == "dealer":
        dealer_profile = db.query(Dealer).filter(Dealer.user_id == recipient_user.id).first()
        if dealer_profile and not dealer_profile.is_claimed:
            # Generate Magic Link JWT
            expiration = datetime.utcnow() + timedelta(days=7)  # Link valid for 7 days
            payload = {
                "sub": str(recipient_user.id),
                "email": recipient_user.email,
                "role": "dealer",
                "conv_id": conversation_id,
                "exp": expiration
            }
            magic_token = jwt.encode(payload, settings.SECRET_KEY, algorithm="HS256")
            magic_link = f"http://localhost:3000/claim-account?token={magic_token}"
            
            # Mock External Service Email/SMS
            logger.warning("=====================================================")
            logger.warning(f"MOCK EMAIL DISPATCH TO {recipient_user.email}")
            logger.warning(f"A customer has a question about a recent contract.")
            logger.warning(f"Click here to securely reply: {magic_link}")
            logger.warning("=====================================================")

    db.commit()
    db.refresh(new_message)
    
    return new_message
