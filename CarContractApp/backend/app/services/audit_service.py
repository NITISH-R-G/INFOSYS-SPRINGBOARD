"""
Audit Service (Gap 9)
Centralized activity logging utility for the audit_logs table.
Records all contract lifecycle events for compliance tracking.
"""
import logging
from datetime import datetime
from typing import Optional, Any, Dict
from sqlalchemy.orm import Session

from ..database import AuditLog

logger = logging.getLogger(__name__)


# ==================== Action Constants ====================

class AuditAction:
    """Predefined audit action strings"""
    CONTRACT_UPLOADED = "contract.uploaded"
    CONTRACT_ANALYZED = "contract.analyzed"
    CONTRACT_DELETED = "contract.deleted"
    CONTRACT_STATUS_CHANGED = "contract.status_changed"
    OCR_COMPLETED = "ocr.completed"
    OCR_FAILED = "ocr.failed"
    LLM_ANALYSIS_STARTED = "llm.analysis_started"
    LLM_ANALYSIS_COMPLETED = "llm.analysis_completed"
    LLM_ANALYSIS_FAILED = "llm.analysis_failed"
    VIN_LOOKUP = "vin.lookup"
    PRICE_ESTIMATED = "price.estimated"
    NEGOTIATION_STARTED = "negotiation.started"
    NEGOTIATION_MESSAGE = "negotiation.message"
    EMAIL_GENERATED = "email.generated"
    USER_REGISTERED = "user.registered"
    USER_LOGIN = "user.login"


# ==================== Logging Utility ====================

def log_event(
    db: Session,
    user_id: Optional[int],
    action: str,
    entity_type: Optional[str] = None,
    entity_id: Optional[int] = None,
    details: Optional[Dict[str, Any]] = None,
    ip_address: Optional[str] = None
) -> AuditLog:
    """
    Insert an audit event into the audit_logs table.

    Args:
        db: Database session
        user_id: ID of the user performing the action (None for system events)
        action: Action string (use AuditAction constants)
        entity_type: Type of entity being acted upon (e.g., "contract", "vehicle")
        entity_id: ID of the entity being acted upon
        details: Additional JSON details about the event
        ip_address: Client IP address

    Returns:
        The created AuditLog record
    """
    try:
        audit_entry = AuditLog(
            user_id=user_id,
            action=action,
            entity_type=entity_type,
            entity_id=entity_id,
            details=details,
            ip_address=ip_address,
            created_at=datetime.utcnow()
        )
        db.add(audit_entry)
        # Don't commit here — let the caller's transaction handle it
        db.flush()

        logger.info(
            f"Audit: [{action}] user={user_id} entity={entity_type}:{entity_id}"
        )
        return audit_entry
    except Exception as e:
        # Audit logging should never break the main flow
        logger.error(f"Audit logging failed: {e}")
        return None


def get_client_ip(request) -> Optional[str]:
    """Extract client IP from FastAPI Request object"""
    try:
        # Check X-Forwarded-For header first (for proxy/load balancer)
        forwarded = request.headers.get("x-forwarded-for")
        if forwarded:
            return forwarded.split(",")[0].strip()
        # Fall back to direct client
        if request.client:
            return request.client.host
    except Exception:
        pass
    return None
