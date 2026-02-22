"""
Magic Link Router
Handles validating JWT Magic Links and claiming Dealer accounts
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from jose import jwt, JWTError
from pydantic import BaseModel, Field

from ..database import get_db, User, Dealer
from ..config import settings
from ..services.auth_service import get_password_hash

router = APIRouter(prefix="/api/magic-link", tags=["Magic Links"])

class ClaimAccountRequest(BaseModel):
    token: str
    new_password: str = Field(..., min_length=8)

class ValidateTokenRequest(BaseModel):
    token: str

@router.post("/validate")
def validate_magic_link(request: ValidateTokenRequest):
    """
    Validate a magic link token
    """
    try:
        payload = jwt.decode(request.token, settings.SECRET_KEY, algorithms=["HS256"])
        user_id = payload.get("sub")
        if user_id is None:
            raise HTTPException(status_code=400, detail="Invalid token payload")
            
        return {"valid": True, "email": payload.get("email"), "user_id": user_id, "conversation_id": payload.get("conv_id")}
    except JWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token is invalid or expired"
        )

@router.post("/claim")
def claim_dealer_account(
    request: ClaimAccountRequest,
    db: Session = Depends(get_db)
):
    """
    Dealers use this endpoint to set their password and claim their Shadow Profile
    """
    try:
        payload = jwt.decode(request.token, settings.SECRET_KEY, algorithms=["HS256"])
        user_id = payload.get("sub")
        if user_id is None:
            raise HTTPException(status_code=400, detail="Invalid token payload")
            
        # 1. Update User password
        user = db.query(User).filter(User.id == int(user_id)).first()
        if not user:
            raise HTTPException(status_code=404, detail="User not found")
            
        user.hashed_password = get_password_hash(request.new_password)
        
        # 2. Update Dealer Profile to claimed
        dealer = db.query(Dealer).filter(Dealer.user_id == user.id).first()
        if dealer:
            dealer.is_claimed = True
            
        db.commit()
        
        return {"success": True, "message": "Account successfully claimed. You can now log in."}
        
    except JWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token is invalid or expired"
        )
