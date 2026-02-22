"""
Database Models and Connection
SQLAlchemy ORM models for the Car Contract App

Strict relational schema with normalized tables:
- users, contracts, contract_files, contract_pages
- extracted_clauses, contract_sla
- vehicles, dealers, lenders
- negotiations, conversations, messages, audit_logs
"""
from datetime import datetime
from typing import Optional
from sqlalchemy import (
    create_engine, Column, Integer, String, Float, Boolean,
    Text, DateTime, ForeignKey, JSON, Numeric, Enum
)
from sqlalchemy.orm import declarative_base, sessionmaker, relationship
from .config import settings

import enum


# ==================== Enums ====================

class ContractStatus(str, enum.Enum):
    pending = "pending"
    queued = "queued"
    scanning = "scanning"
    extracting = "extracting"
    analyzing = "analyzing"
    analyzed = "analyzed"
    error = "error"


class RiskLevel(str, enum.Enum):
    low = "low"
    medium = "medium"
    high = "high"


class UserRole(str, enum.Enum):
    buyer = "buyer"
    dealer = "dealer"
    admin = "admin"


# ==================== Database Engine ====================

def _create_engine():
    """Create database engine based on DATABASE_URL"""
    url = settings.DATABASE_URL
    if not url:
        raise ValueError("DATABASE_URL is not configured. Set it in your .env file.")

    connect_args = {}
    if "sqlite" in url:
        connect_args["check_same_thread"] = False

    return create_engine(url, connect_args=connect_args, pool_pre_ping=True)


engine = _create_engine()
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()


# ==================== Models ====================

class User(Base):
    """User accounts for authentication"""
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String(255), unique=True, index=True, nullable=False)
    full_name = Column(String(255))
    hashed_password = Column(String(255), nullable=False)
    role = Column(String(50), default="buyer")  # buyer, dealer, admin
    phone_number = Column(String(20), nullable=True)
    profile_image_url = Column(String(500), nullable=True)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    contracts = relationship("Contract", back_populates="user")
    negotiations = relationship("Negotiation", back_populates="user")
    conversations_as_buyer = relationship("Conversation", foreign_keys="[Conversation.buyer_id]", back_populates="buyer")
    conversations_as_dealer = relationship("Conversation", foreign_keys="[Conversation.dealer_id]", back_populates="dealer")


class Vehicle(Base):
    """Vehicle information from VIN lookup"""
    __tablename__ = "vehicles"

    id = Column(Integer, primary_key=True, index=True)
    vin = Column(String(17), unique=True, index=True)
    make = Column(String(100))
    model = Column(String(100))
    year = Column(Integer)
    trim = Column(String(100))
    body_type = Column(String(100))
    engine = Column(String(200))
    transmission = Column(String(100))
    drivetrain = Column(String(50))
    fuel_type = Column(String(50))

    # Pricing & History
    estimated_value = Column(Float)
    mileage = Column(Integer)
    recalls = Column(JSON)

    # Metadata
    source = Column(String(50), default="NHTSA")
    fetched_at = Column(DateTime, default=datetime.utcnow)

    # Relationships
    contracts = relationship("Contract", back_populates="vehicle")


class Dealer(Base):
    """Dealer/Seller information"""
    __tablename__ = "dealers"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(255), nullable=False)
    address = Column(Text)
    phone = Column(String(20))
    email = Column(String(255))
    website = Column(String(255))
    rating = Column(Float)
    
    # Shadow Profile integration
    is_claimed = Column(Boolean, default=False)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=True)

    contracts = relationship("Contract", back_populates="dealer")
    user = relationship("User", foreign_keys=[user_id])


class Lender(Base):
    """Lender/Financial institution information"""
    __tablename__ = "lenders"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(255), nullable=False)
    type = Column(String(50))  # bank, credit_union, dealer_finance, captive
    address = Column(Text)
    phone = Column(String(20))
    website = Column(String(255))

    contracts = relationship("Contract", back_populates="lender")


class Contract(Base):
    """Uploaded contract documents — parent record"""
    __tablename__ = "contracts"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    vehicle_id = Column(Integer, ForeignKey("vehicles.id"), nullable=True)
    dealer_id = Column(Integer, ForeignKey("dealers.id"), nullable=True)
    lender_id = Column(Integer, ForeignKey("lenders.id"), nullable=True)

    # Contract Type
    contract_type = Column(String(20))  # lease, loan, sale

    # Async Processing
    job_id = Column(String(100), index=True, nullable=True)
    status = Column(String(20), default="pending")
    error_message = Column(Text, nullable=True)

    # Legacy text storage (kept for backward compat during migration)
    raw_text = Column(Text, nullable=True)

    # Analysis Results (denormalized for fast reads)
    fairness_score = Column(Integer, nullable=True)
    fairness_explanation = Column(Text, nullable=True)
    confidence_score = Column(Integer, nullable=True)

    # Detailed 12-Section Analysis (Sprint 9 — kept as JSON for backward compat)
    detailed_analysis = Column(JSON, nullable=True)

    # Red flags (legacy JSON, will gradually migrate to extracted_clauses)
    red_flags = Column(JSON, nullable=True)

    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow)
    analyzed_at = Column(DateTime, nullable=True)

    # Relationships
    user = relationship("User", back_populates="contracts")
    vehicle = relationship("Vehicle", back_populates="contracts")
    dealer = relationship("Dealer", back_populates="contracts")
    lender = relationship("Lender", back_populates="contracts")
    files = relationship("ContractFile", back_populates="contract", cascade="all, delete-orphan")
    sla = relationship("ContractSLA", back_populates="contract", uselist=False, cascade="all, delete-orphan")
    clauses = relationship("ExtractedClause", back_populates="contract", cascade="all, delete-orphan")


class ContractFile(Base):
    """Normalized file storage — one contract can have many files"""
    __tablename__ = "contract_files"

    id = Column(Integer, primary_key=True, index=True)
    contract_id = Column(Integer, ForeignKey("contracts.id", ondelete="CASCADE"), nullable=False)
    filename = Column(String(255), nullable=False)
    file_path = Column(String(500), nullable=False)
    file_type = Column(String(20))  # pdf, image
    page_count = Column(Integer, nullable=True)
    file_size_bytes = Column(Integer, nullable=True)
    uploaded_at = Column(DateTime, default=datetime.utcnow)

    # Relationships
    contract = relationship("Contract", back_populates="files")
    pages = relationship("ContractPage", back_populates="file", cascade="all, delete-orphan")


class ContractPage(Base):
    """Per-page OCR results"""
    __tablename__ = "contract_pages"

    id = Column(Integer, primary_key=True, index=True)
    contract_file_id = Column(Integer, ForeignKey("contract_files.id", ondelete="CASCADE"), nullable=False)
    page_number = Column(Integer, nullable=False)
    raw_text = Column(Text, nullable=True)
    ocr_confidence = Column(Float, nullable=True)  # 0.0 - 100.0
    processing_time_ms = Column(Integer, nullable=True)

    # Relationships
    file = relationship("ContractFile", back_populates="pages")


class ContractSLA(Base):
    """Structured SLA parameters — one per contract"""
    __tablename__ = "contract_sla"

    id = Column(Integer, primary_key=True, index=True)
    contract_id = Column(Integer, ForeignKey("contracts.id", ondelete="CASCADE"), nullable=False, unique=True)

    # Financial Terms
    currency_code = Column(String(3), default="USD")
    apr = Column(Float, nullable=True)
    term_months = Column(Integer, nullable=True)
    monthly_payment = Column(Float, nullable=True)
    down_payment = Column(Float, nullable=True)
    residual_value = Column(Float, nullable=True)
    buyout_price = Column(Float, nullable=True)
    documentation_fee = Column(Float, nullable=True)
    acquisition_fee = Column(Float, nullable=True)
    disposition_fee = Column(Float, nullable=True)

    # Usage Terms
    mileage_limit = Column(Integer, nullable=True)
    mileage_overage_fee = Column(Float, nullable=True)
    early_termination_fee = Column(String(255), nullable=True)
    maintenance_included = Column(Boolean, nullable=True)
    warranty_months = Column(Integer, nullable=True)

    # Market Value Analysis
    market_value = Column(Float, nullable=True)
    market_value_high = Column(Float, nullable=True)
    market_value_low = Column(Float, nullable=True)
    market_confidence = Column(String(20), nullable=True)

    # Scoring
    fairness_score = Column(Integer, nullable=True)
    fairness_explanation = Column(Text, nullable=True)

    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow)

    # Relationships
    contract = relationship("Contract", back_populates="sla")


class ExtractedClause(Base):
    """Individual clause extractions from a contract"""
    __tablename__ = "extracted_clauses"

    id = Column(Integer, primary_key=True, index=True)
    contract_id = Column(Integer, ForeignKey("contracts.id", ondelete="CASCADE"), nullable=False)

    # Section identification
    section_key = Column(String(100), nullable=False)  # e.g. "lease_payment_terms"
    section_title = Column(String(255), nullable=True)

    # Content
    clause_text = Column(Text, nullable=False)
    risk_level = Column(String(10), nullable=True)  # low, medium, high
    risk_reason = Column(Text, nullable=True)
    suggestion = Column(Text, nullable=True)

    # Source location
    source_page = Column(Integer, nullable=True)
    coordinates = Column(JSON, nullable=True)  # [{page, rect}]

    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow)

    # Relationships
    contract = relationship("Contract", back_populates="clauses")


class Negotiation(Base):
    """AI negotiation chat history"""
    __tablename__ = "negotiations"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    contract_id = Column(Integer, ForeignKey("contracts.id"), nullable=True)
    session_id = Column(String(50), index=True)
    messages = Column(JSON)
    generated_emails = Column(JSON)
    negotiation_points = Column(JSON)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    user = relationship("User", back_populates="negotiations")


class Conversation(Base):
    """Human-to-Human conversation thread between a Buyer and a Dealer"""
    __tablename__ = "conversations"

    id = Column(Integer, primary_key=True, index=True)
    buyer_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    dealer_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    contract_id = Column(Integer, ForeignKey("contracts.id"), nullable=True)
    subject = Column(String(255), nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    buyer = relationship("User", foreign_keys=[buyer_id], back_populates="conversations_as_buyer")
    dealer = relationship("User", foreign_keys=[dealer_id], back_populates="conversations_as_dealer")
    messages = relationship("Message", back_populates="conversation", order_by="Message.created_at")
    contract = relationship("Contract", foreign_keys=[contract_id])


class Message(Base):
    """Individual human message inside a Conversation"""
    __tablename__ = "messages"

    id = Column(Integer, primary_key=True, index=True)
    conversation_id = Column(Integer, ForeignKey("conversations.id"), nullable=False)
    sender_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    content = Column(Text, nullable=False)
    is_read = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)

    conversation = relationship("Conversation", back_populates="messages")
    sender = relationship("User", foreign_keys=[sender_id])


class AuditLog(Base):
    """Activity/Action tracking for compliance"""
    __tablename__ = "audit_logs"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    action = Column(String(100), nullable=False)
    entity_type = Column(String(50))
    entity_id = Column(Integer)
    details = Column(JSON)
    ip_address = Column(String(45))
    created_at = Column(DateTime, default=datetime.utcnow)


# ==================== Database Functions ====================

def get_db():
    """Dependency for FastAPI to get database session"""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def init_db():
    """Initialize database tables (dev only — use Alembic in production)"""
    Base.metadata.create_all(bind=engine)
    print("[+] Database tables created successfully!")


if __name__ == "__main__":
    init_db()
