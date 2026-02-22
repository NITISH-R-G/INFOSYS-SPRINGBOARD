"""
Car Contract Review and Negotiation AI Assistant
FastAPI Main Application
"""
import logging
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager

from .config import settings
from .database import init_db
from .routers import contracts, vehicles, negotiations, files, auth, messaging, ws, intake, audit, magic_link
from .exceptions import AppException, app_exception_handler, global_exception_handler

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(name)s: %(message)s")
logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan handler - runs on startup and shutdown"""
    # Startup
    logger.info("Starting Car Contract Review API...")
    init_db()
    logger.info("Database initialized")
    logger.info("API Docs available at: http://localhost:8000/docs")
    yield
    # Shutdown
    logger.info("Shutting down...")


# Create FastAPI app
app = FastAPI(
    title=settings.APP_NAME,
    version=settings.APP_VERSION,
    description="""
## Car Contract Review and Negotiation AI Assistant

An AI-powered application to help consumers review, understand, and negotiate their car lease/loan contracts.

### Features

- **📄 Contract Upload & OCR**: Upload PDF/image contracts for text extraction
- **🤖 AI-Powered SLA Extraction**: Automatically extract key terms (APR, payments, mileage, penalties)
- **📊 Contract Fairness Score**: Get a 0-100 score evaluating contract fairness
- **🚩 Red Flag Detection**: Identify hidden fees and risky clauses
- **🔍 VIN Lookup**: Get vehicle history and recall information via NHTSA API
- **💬 AI Negotiation Assistant**: Get help negotiating better terms
- **💰 Price Estimation**: Compare with fair market values
- **⚡ Background Processing**: Async document parsing with real-time progress updates
    """,
    lifespan=lifespan,
    docs_url="/docs",
    redoc_url="/redoc"
)

# Configure CORS — allow all origins for local development (Flutter web uses random ports)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Register exception handlers
app.add_exception_handler(AppException, app_exception_handler)
app.add_exception_handler(Exception, global_exception_handler)

# Include routers
app.include_router(auth.router)
app.include_router(contracts.router)
app.include_router(vehicles.router)
app.include_router(negotiations.router)
app.include_router(files.router)
app.include_router(messaging.router)
app.include_router(ws.router)
app.include_router(intake.router)
app.include_router(audit.router)
app.include_router(magic_link.router)


@app.get("/", tags=["Health"])
async def root():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "app": settings.APP_NAME,
        "version": settings.APP_VERSION,
        "docs": "/docs"
    }


@app.get("/health", tags=["Health"])
async def health_check():
    """Detailed health check"""
    return {
        "status": "healthy",
        "services": {
            "api": "running",
            "database": "connected",
            "gemini": "configured" if settings.GEMINI_API_KEY else "not configured"
        }
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "app.main:app",
        host="127.0.0.1",
        port=8000,
        reload=settings.DEBUG
    )
