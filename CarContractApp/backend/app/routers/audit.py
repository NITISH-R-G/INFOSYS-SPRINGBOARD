"""
Audit Router (Gap 9)
Endpoints for retrieving audit trail history.
"""
import logging
from typing import List, Optional
from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from ..database import get_db, AuditLog, User
from ..services.auth_service import get_current_active_user
from ..models.schemas import AuditLogResponse

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/audit", tags=["Audit Trail"])


@router.get("/", response_model=List[AuditLogResponse])
async def list_audit_events(
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=200),
    action: Optional[str] = Query(None, description="Filter by action type"),
    entity_type: Optional[str] = Query(None, description="Filter by entity type"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """
    List audit events for the current user (paginated).
    Admins can see all events; non-admins see only their own.
    """
    query = db.query(AuditLog)

    # Non-admin users only see their own events
    if current_user.role != "admin":
        query = query.filter(AuditLog.user_id == current_user.id)

    # Optional filters
    if action:
        query = query.filter(AuditLog.action == action)
    if entity_type:
        query = query.filter(AuditLog.entity_type == entity_type)

    events = query.order_by(
        AuditLog.created_at.desc()
    ).offset(skip).limit(limit).all()

    return events


@router.get("/{entity_type}/{entity_id}", response_model=List[AuditLogResponse])
async def get_entity_audit_trail(
    entity_type: str,
    entity_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """
    Get the complete audit trail for a specific entity.
    For example: /audit/contract/5 — returns all events for contract ID 5.
    """
    query = db.query(AuditLog).filter(
        AuditLog.entity_type == entity_type,
        AuditLog.entity_id == entity_id
    )

    # Non-admin users only see their own events
    if current_user.role != "admin":
        query = query.filter(AuditLog.user_id == current_user.id)

    events = query.order_by(AuditLog.created_at.asc()).all()

    return events
