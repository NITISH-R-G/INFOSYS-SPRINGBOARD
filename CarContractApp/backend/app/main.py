"""
Car Contract Review and Negotiation AI Assistant
FastAPI Main Application
"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager

from .config import settings
from .database import init_db
from .routers import contracts, vehicles, negotiations, files


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan handler - runs on startup and shutdown"""
    # Startup
    print("[*] Starting Car Contract Review API...")
    init_db()
    print("[+] Database initialized")
    print("[i] API Docs available at: http://localhost:8000/docs")
    yield
    # Shutdown
    print("[*] Shutting down...")


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
    """,
    lifespan=lifespan,
    docs_url="/docs",
    redoc_url="/redoc"
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify actual origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(contracts.router)
app.include_router(vehicles.router)
app.include_router(negotiations.router)
app.include_router(files.router)


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
