"""
Custom Exception Classes and Handlers
Typed HTTP exceptions that don't leak Python stack traces to the client.
"""
import uuid
import logging
from fastapi import Request, HTTPException
from fastapi.responses import JSONResponse

logger = logging.getLogger(__name__)


# ==================== Custom Exceptions ====================

class AppException(HTTPException):
    """Base application exception"""
    def __init__(self, status_code: int, detail: str, error_code: str = "APP_ERROR"):
        super().__init__(status_code=status_code, detail=detail)
        self.error_code = error_code


class OCRProcessingError(AppException):
    """OCR extraction failed"""
    def __init__(self, detail: str = "Failed to extract text from the uploaded document."):
        super().__init__(status_code=422, detail=detail, error_code="OCR_PROCESSING_ERROR")


class LLMAnalysisError(AppException):
    """LLM analysis failed or timed out"""
    def __init__(self, detail: str = "AI analysis is temporarily unavailable. Please try again shortly."):
        super().__init__(status_code=503, detail=detail, error_code="LLM_ANALYSIS_ERROR")


class ContractNotFoundError(AppException):
    """Contract not found"""
    def __init__(self, contract_id: int = None):
        detail = "Contract not found"
        if contract_id:
            detail = f"Contract {contract_id} not found"
        super().__init__(status_code=404, detail=detail, error_code="CONTRACT_NOT_FOUND")


class AuthenticationError(AppException):
    """Authentication failed"""
    def __init__(self, detail: str = "Could not validate credentials."):
        super().__init__(status_code=401, detail=detail, error_code="AUTHENTICATION_ERROR")


class ValidationError(AppException):
    """Request validation failed"""
    def __init__(self, detail: str = "Invalid request data."):
        super().__init__(status_code=400, detail=detail, error_code="VALIDATION_ERROR")


class TaskNotFoundError(AppException):
    """Background task not found"""
    def __init__(self, job_id: str = None):
        detail = "Task not found"
        if job_id:
            detail = f"Task {job_id} not found"
        super().__init__(status_code=404, detail=detail, error_code="TASK_NOT_FOUND")


class LowOCRConfidenceError(AppException):
    """OCR confidence is too low for reliable extraction"""
    def __init__(self, confidence: float = 0.0):
        super().__init__(
            status_code=422,
            detail=f"OCR confidence is too low ({confidence:.1f}%). Please upload a clearer image or manually input the data.",
            error_code="LOW_OCR_CONFIDENCE"
        )


# ==================== Global Exception Handler ====================

async def global_exception_handler(request: Request, exc: Exception) -> JSONResponse:
    """
    Catch-all exception handler that returns a generic error
    with a request_id for debugging, without leaking stack traces.
    """
    request_id = str(uuid.uuid4())[:8]
    
    # Log the full error server-side
    logger.error(
        f"Unhandled exception [request_id={request_id}]: {type(exc).__name__}: {exc}",
        exc_info=True
    )
    
    return JSONResponse(
        status_code=500,
        content={
            "detail": "An internal error occurred. Please try again later.",
            "error_code": "INTERNAL_ERROR",
            "request_id": request_id
        }
    )


async def app_exception_handler(request: Request, exc: AppException) -> JSONResponse:
    """Handler for our typed AppException subclasses."""
    return JSONResponse(
        status_code=exc.status_code,
        content={
            "detail": exc.detail,
            "error_code": exc.error_code
        }
    )
