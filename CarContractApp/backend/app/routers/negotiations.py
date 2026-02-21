"""
Negotiations Router  
Handles AI-powered negotiation assistance and email generation
"""
import uuid
from datetime import datetime
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from ..database import get_db, Contract, Negotiation
from ..models.schemas import (
    NegotiationChatRequest, NegotiationChatResponse,
    GenerateEmailRequest, GenerateEmailResponse
)
from ..services.llm_service import llm_service, LLMException

router = APIRouter(prefix="/negotiate", tags=["Negotiation"])

# Default user ID for non-authenticated usage
DEFAULT_USER_ID = 1


@router.post("/chat", response_model=NegotiationChatResponse)
async def negotiation_chat(
    request: NegotiationChatRequest,
    db: Session = Depends(get_db)
):
    """
    AI-powered negotiation assistant chat
    
    Provides advice on negotiating car lease/loan terms
    """
    # Generate or use existing session ID
    session_id = request.session_id or str(uuid.uuid4())
    
    # Build context from contract if provided
    context = request.context or {}
    conversation_history = []
    
    if request.contract_id:
        contract = db.query(Contract).filter(
            Contract.id == request.contract_id
        ).first()
        
        if contract and contract.sla_data:
            context["contract"] = {
                "sla_data": contract.sla_data,
                "fairness_score": contract.fairness_score,
                "red_flags": contract.red_flags,
                "contract_type": contract.contract_type
            }
    
    # Get conversation history if session exists
    negotiation = db.query(Negotiation).filter(
        Negotiation.session_id == session_id
    ).first()
    
    if negotiation and negotiation.messages:
        conversation_history = negotiation.messages
    
    try:
        # Generate response
        result = await llm_service.generate_negotiation_response(
            user_message=request.message,
            context=context,
            conversation_history=conversation_history
        )
        
        # Update conversation history
        new_messages = conversation_history + [
            {"role": "user", "content": request.message, "timestamp": datetime.utcnow().isoformat()},
            {"role": "assistant", "content": result.get("response", ""), "timestamp": datetime.utcnow().isoformat()}
        ]
        
        # Save to database
        if negotiation:
            negotiation.messages = new_messages
            negotiation.negotiation_points = result.get("negotiation_points")
            negotiation.updated_at = datetime.utcnow()
        else:
            negotiation = Negotiation(
                user_id=DEFAULT_USER_ID,
                contract_id=request.contract_id,
                session_id=session_id,
                messages=new_messages,
                negotiation_points=result.get("negotiation_points")
            )
            db.add(negotiation)
        
        db.commit()
        
        return NegotiationChatResponse(
            session_id=session_id,
            response=result.get("response", ""),
            suggested_actions=result.get("suggested_actions"),
            negotiation_points=result.get("negotiation_points")
        )
        
    except LLMException as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Negotiation chat failed: {str(e)}"
        )


@router.post("/generate-email", response_model=GenerateEmailResponse)
async def generate_negotiation_email(
    request: GenerateEmailRequest,
    db: Session = Depends(get_db)
):
    """
    Generate a negotiation email based on contract analysis
    """
    # Get contract data
    contract = db.query(Contract).filter(
        Contract.id == request.contract_id
    ).first()
    
    if not contract:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Contract not found"
        )
    
    if not contract.sla_data:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Contract has not been analyzed yet"
        )
    
    # Build contract data for email generation
    contract_data = {
        "sla_data": contract.sla_data,
        "fairness_score": contract.fairness_score,
        "fairness_explanation": contract.fairness_explanation,
        "red_flags": contract.red_flags,
        "contract_type": contract.contract_type
    }
    
    try:
        result = await llm_service.generate_negotiation_email(
            contract_data=contract_data,
            email_type=request.email_type,
            specific_points=request.specific_points,
            tone=request.tone
        )
        
        return GenerateEmailResponse(
            subject=result.get("subject", "Regarding My Car Lease/Loan"),
            body=result.get("body", ""),
            key_points=result.get("key_points", [])
        )
        
    except LLMException as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Email generation failed: {str(e)}"
        )


@router.get("/history/{session_id}")
async def get_negotiation_history(
    session_id: str,
    db: Session = Depends(get_db)
):
    """
    Get conversation history for a negotiation session
    """
    negotiation = db.query(Negotiation).filter(
        Negotiation.session_id == session_id
    ).first()
    
    if not negotiation:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Negotiation session not found"
        )
    
    return {
        "session_id": session_id,
        "contract_id": negotiation.contract_id,
        "messages": negotiation.messages or [],
        "negotiation_points": negotiation.negotiation_points,
        "created_at": negotiation.created_at,
        "updated_at": negotiation.updated_at
    }


@router.get("/tips")
async def get_negotiation_tips(
    contract_type: Optional[str] = None
):
    """
    Get general negotiation tips for car leases/loans
    """
    general_tips = [
        "Always get quotes from multiple dealers/lenders before negotiating",
        "Focus on the total cost, not just monthly payments",
        "Negotiate the vehicle price before discussing financing",
        "Know your credit score before applying for financing",
        "Be prepared to walk away - it's your strongest negotiating tool",
        "Time your purchase at the end of the month/quarter when dealers have quotas",
        "Don't reveal your trade-in or down payment until price is agreed",
        "Get pre-approved financing from a bank or credit union as leverage"
    ]
    
    lease_tips = [
        "Negotiate the capitalized cost (selling price) down",
        "Ask about money factor and convert to APR (multiply by 2400)",
        "Negotiate the residual value if possible",
        "Avoid excessive mileage limits that will cost you later",
        "Watch for hidden acquisition and disposition fees",
        "Consider multiple security deposits to lower money factor"
    ]
    
    loan_tips = [
        "Shop for the best APR across multiple lenders",
        "Shorter loan terms mean less interest paid overall",
        "Avoid extended warranties sold through the dealer",
        "Watch for prepayment penalties in the fine print",
        "Consider a larger down payment to reduce interest costs",
        "Don't focus only on monthly payment - consider total cost"
    ]
    
    tips = {
        "general": general_tips,
        "lease": lease_tips if contract_type in [None, "lease"] else [],
        "loan": loan_tips if contract_type in [None, "loan"] else []
    }
    
    return tips
