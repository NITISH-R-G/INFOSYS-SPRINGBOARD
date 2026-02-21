"""
Database Models and Connection
SQLAlchemy ORM models for the Car Contract App
"""
from datetime import datetime
from typing import Optional
from sqlalchemy import (
    create_engine, Column, Integer, String, Float, Boolean, 
    Text, DateTime, ForeignKey, JSON, LargeBinary
)
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, relationship
from .config import settings

# Database engine
engine = create_engine(
    settings.DATABASE_URL, 
    connect_args={"check_same_thread": False} if "sqlite" in settings.DATABASE_URL else {}
)

# Session factory
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Base class for models
Base = declarative_base()


# ==================== Models ====================

class User(Base):
    """User accounts for authentication"""
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, index=True)
    email = Column(String(255), unique=True, index=True, nullable=False)
    full_name = Column(String(255))
    hashed_password = Column(String(255), nullable=False)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    contracts = relationship("Contract", back_populates="user")
    negotiations = relationship("Negotiation", back_populates="user")


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
    recalls = Column(JSON)  # List of recall records
    
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
    
    # Relationships
    contracts = relationship("Contract", back_populates="dealer")


class Lender(Base):
    """Lender/Financial institution information"""
    __tablename__ = "lenders"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(255), nullable=False)
    type = Column(String(50))  # bank, credit_union, dealer_finance, captive
    address = Column(Text)
    phone = Column(String(20))
    website = Column(String(255))
    
    # Relationships
    contracts = relationship("Contract", back_populates="lender")


class Contract(Base):
    """Uploaded contract documents with extracted data"""
    __tablename__ = "contracts"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    vehicle_id = Column(Integer, ForeignKey("vehicles.id"))
    dealer_id = Column(Integer, ForeignKey("dealers.id"))
    lender_id = Column(Integer, ForeignKey("lenders.id"))
    
    # Document Info
    filename = Column(String(255))
    file_path = Column(String(500))
    file_type = Column(String(20))  # pdf, image
    raw_text = Column(Text)  # OCR extracted text
    
    # Contract Type
    contract_type = Column(String(20))  # lease, loan
    
    # Extracted SLA Data (JSON)
    sla_data = Column(JSON)
    """
    {
        "apr": 5.9,
        "term_months": 36,
        "monthly_payment": 450.00,
        "down_payment": 2000.00,
        "residual_value": 18500.00,
        "mileage_limit": 12000,
        "mileage_overage_fee": 0.25,
        "early_termination_fee": "3 months payment",
        "buyout_price": 18500.00,
        "maintenance_included": false,
        "warranty_months": 36
    }
    """
    
    # Detailed 12-Section Analysis (Sprint 9)
    detailed_analysis = Column(JSON)


    # Analysis Results
    fairness_score = Column(Integer)  # 0-100
    fairness_explanation = Column(Text)
    red_flags = Column(JSON)  # List of identified issues
    confidence_score = Column(Integer)  # 0-100, LLM confidence
    
    # Status
    status = Column(String(20), default="pending")  # pending, processing, analyzed, error
    error_message = Column(Text)
    
    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow)
    analyzed_at = Column(DateTime)
    
    # Relationships
    user = relationship("User", back_populates="contracts")
    vehicle = relationship("Vehicle", back_populates="contracts")
    dealer = relationship("Dealer", back_populates="contracts")
    lender = relationship("Lender", back_populates="contracts")


class Negotiation(Base):
    """AI negotiation chat history"""
    __tablename__ = "negotiations"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    contract_id = Column(Integer, ForeignKey("contracts.id"))
    
    # Session Info
    session_id = Column(String(50), index=True)
    
    # Conversation
    messages = Column(JSON)  # List of {role, content, timestamp}
    """
    [
        {"role": "user", "content": "...", "timestamp": "..."},
        {"role": "assistant", "content": "...", "timestamp": "..."}
    ]
    """
    
    # Generated Content
    generated_emails = Column(JSON)  # List of generated negotiation emails
    negotiation_points = Column(JSON)  # Suggested talking points
    
    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    user = relationship("User", back_populates="negotiations")


class AuditLog(Base):
    """Activity/Action tracking for compliance"""
    __tablename__ = "audit_logs"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    action = Column(String(100), nullable=False)
    entity_type = Column(String(50))  # contract, vehicle, negotiation
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
    """Initialize database tables"""
    Base.metadata.create_all(bind=engine)
    print("[+] Database tables created successfully!")


if __name__ == "__main__":
    init_db()
