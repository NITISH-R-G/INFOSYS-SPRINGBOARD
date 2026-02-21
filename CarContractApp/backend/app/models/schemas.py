"""
Pydantic Schemas for API Request/Response validation
"""
from datetime import datetime
from typing import Optional, List, Any, Union
from pydantic import BaseModel, EmailStr, Field


# ==================== Auth Schemas ====================

class UserCreate(BaseModel):
    """Schema for user registration"""
    email: EmailStr
    full_name: str = Field(..., min_length=2, max_length=255)
    password: str = Field(..., min_length=8)


class UserLogin(BaseModel):
    """Schema for user login"""
    email: EmailStr
    password: str


class UserResponse(BaseModel):
    """Schema for user response (without password)"""
    id: int
    email: str
    full_name: str
    is_active: bool
    created_at: datetime
    
    class Config:
        from_attributes = True


class Token(BaseModel):
    """JWT token response"""
    access_token: str
    token_type: str = "bearer"


class TokenData(BaseModel):
    """Token payload data"""
    email: Optional[str] = None
    user_id: Optional[int] = None


# ==================== Contract Schemas ====================

class SLAData(BaseModel):
    """Extracted SLA/Contract terms"""
    apr: Optional[float] = Field(None, description="Annual Percentage Rate")
    term_months: Optional[int] = Field(None, description="Lease/Loan term in months")
    monthly_payment: Optional[float] = Field(None, description="Monthly payment amount")
    down_payment: Optional[float] = Field(None, description="Down payment amount")
    residual_value: Optional[float] = Field(None, description="Vehicle residual value")
    mileage_limit: Optional[int] = Field(None, description="Annual mileage limit")
    mileage_overage_fee: Optional[float] = Field(None, description="Per-mile overage fee")
    early_termination_fee: Optional[str] = Field(None, description="Early termination penalty")
    buyout_price: Optional[float] = Field(None, description="Purchase/buyout price")
    maintenance_included: Optional[bool] = Field(None, description="Is maintenance included?")
    warranty_months: Optional[int] = Field(None, description="Warranty duration in months")
    documentation_fee: Optional[float] = Field(None, description="Documentation/admin fee")
    acquisition_fee: Optional[float] = Field(None, description="Lease acquisition fee")
    disposition_fee: Optional[float] = Field(None, description="Lease end disposition fee")
    
    # Market Value Analysis (Augmented)
    market_value: Optional[float] = Field(None, description="Estimated fair market value")
    market_value_high: Optional[float] = Field(None, description="High end of market range")
    market_value_low: Optional[float] = Field(None, description="Low end of market range")
    market_confidence: Optional[str] = Field(None, description="Confidence in market value")


# ==================== Detailed Analysis Schemas (Sprint 9) ====================

class ReviewRisk(BaseModel):
    """Risk flag within a specific section"""
    clause: str
    reason: str

class SectionVehicleDetails(BaseModel):
    make: str = "Not Mentioned"
    model: str = "Not Mentioned"
    variant_trim: str = "Not Mentioned"
    manufacturing_year: str = "Not Mentioned"
    vin: str = "Not Mentioned"
    registration_number: str = "Not Mentioned"
    vehicle_condition: str = "Not Mentioned"
    risk_flags: List[ReviewRisk] = []

class SectionLeasePayments(BaseModel):
    monthly_payment_amount: str = "Not Mentioned"
    security_deposit: str = "Not Mentioned"
    payment_due_date: str = "Not Mentioned"
    late_payment_penalties: str = "Not Mentioned"
    taxes_and_charges: str = "Not Mentioned"
    risk_flags: List[ReviewRisk] = []

class SectionLeaseDuration(BaseModel):
    lease_start_date: str = "Not Mentioned"
    lease_end_date: str = "Not Mentioned"
    total_lease_period: str = "Not Mentioned"
    risk_flags: List[ReviewRisk] = []

class SectionMileage(BaseModel):
    allowed_mileage_limit: str = "Not Mentioned"
    excess_mileage_charges: str = "Not Mentioned"
    risk_flags: List[ReviewRisk] = []

class SectionMaintenance(BaseModel):
    regular_maintenance_responsibility: str = "Not Mentioned"
    repair_cost_responsibility: str = "Not Mentioned"
    modification_restrictions: str = "Not Mentioned"
    vehicle_condition_requirements: str = "Not Mentioned"
    risk_flags: List[ReviewRisk] = []

class SectionInsurance(BaseModel):
    required_insurance_type: str = "Not Mentioned"
    insurance_payment_responsibility: str = "Not Mentioned"
    accident_liability_terms: str = "Not Mentioned"
    risk_flags: List[ReviewRisk] = []

class SectionDamage(BaseModel):
    normal_wear_and_tear_definition: str = "Not Mentioned"
    excess_damage_charges: str = "Not Mentioned"
    return_inspection_process: str = "Not Mentioned"
    risk_flags: List[ReviewRisk] = []

class SectionEarlyTermination(BaseModel):
    early_termination_allowed: str = "Not Mentioned"
    termination_charges: str = "Not Mentioned"
    cancellation_conditions: str = "Not Mentioned"
    contract_breach_consequences: str = "Not Mentioned"
    risk_flags: List[ReviewRisk] = []

class SectionOwnership(BaseModel):
    vehicle_ownership_holder: str = "Not Mentioned"
    end_of_lease_purchase_option: str = "Not Mentioned"
    purchase_price_or_formula: str = "Not Mentioned"
    vehicle_return_conditions: str = "Not Mentioned"
    risk_flags: List[ReviewRisk] = []

class SectionUsageRestrictions(BaseModel):
    authorized_drivers: str = "Not Mentioned"
    commercial_use_restrictions: str = "Not Mentioned"
    geographic_usage_restrictions: str = "Not Mentioned"
    risk_flags: List[ReviewRisk] = []

class SectionLegal(BaseModel):
    default_conditions: str = "Not Mentioned"
    repossession_rights: str = "Not Mentioned"
    dispute_resolution_method: str = "Not Mentioned"
    risk_flags: List[ReviewRisk] = []

class SectionEndOfLease(BaseModel):
    return_procedure: str = "Not Mentioned"
    renewal_options: str = "Not Mentioned"
    final_settlement_terms: str = "Not Mentioned"
    risk_flags: List[ReviewRisk] = []

class DetailedAnalysis(BaseModel):
    """Comprehensive 12-section analysis result"""
    vehicle_details: SectionVehicleDetails
    lease_payment_terms: SectionLeasePayments
    lease_duration: SectionLeaseDuration
    mileage_usage_limits: SectionMileage
    maintenance_responsibilities: SectionMaintenance
    insurance_requirements: SectionInsurance
    damage_and_wear_conditions: SectionDamage
    early_termination_terms: SectionEarlyTermination
    ownership_terms: SectionOwnership
    usage_restrictions: SectionUsageRestrictions
    default_and_legal_clauses: SectionLegal
    end_of_lease_process: SectionEndOfLease
    missing_sections: List[str] = []
    summary: str = "Analysis completed."
    confidence_score: int = 0


class RedFlag(BaseModel):
    """Structured red flag with clause text and explanation"""
    clause_text: str = Field(..., description="Exact text from document containing the issue")
    title: str = Field(..., description="Short title like 'High APR' or 'Hidden Fee'")
    risk_level: str = Field(..., description="high, medium, or low")
    why_flag: str = Field(..., description="Why this clause is a red flag")
    risks: str = Field(..., description="Potential risks or implications for the user")
    plain_explanation: str = Field(..., description="Simple non-legal explanation")
    suggestion: str = Field(..., description="What to verify, negotiate, or be cautious about")


class ContractAnalysisResult(BaseModel):
    """Complete contract analysis result"""
    sla_data: SLAData
    fairness_score: int = Field(..., ge=0, le=100, description="Contract fairness score 0-100")
    fairness_explanation: str = Field(..., description="Explanation for fairness score")
    red_flags: List[Union[dict, str]] = Field(default_factory=list, description="Identified red flags with details")
    confidence_score: int = Field(..., ge=0, le=100, description="Analysis confidence 0-100")
    contract_type: Optional[str] = Field(None, description="lease or loan")
    detailed_analysis: Optional[DetailedAnalysis] = None  # Sprint 9: Nested 12-section analysis


class ContractUploadResponse(BaseModel):
    """Response after contract upload"""
    id: int
    filename: str
    status: str
    raw_text: Optional[str] = None
    message: str


class ContractResponse(BaseModel):
    """Full contract response with analysis"""
    id: int
    filename: str
    contract_type: Optional[str]
    status: str
    raw_text: Optional[str]
    sla_data: Optional[dict]
    detailed_analysis: Optional[DetailedAnalysis] = None  # Sprint 9 addition
    fairness_score: Optional[int]
    fairness_explanation: Optional[str]
    red_flags: Optional[List[Union[dict, str]]]
    confidence_score: Optional[int]
    created_at: datetime
    analyzed_at: Optional[datetime]
    vehicle: Optional[dict] = None
    vin_lookup: Optional[dict] = None  # Auto-detected VIN lookup results
    
    class Config:
        from_attributes = True


class ContractCompareRequest(BaseModel):
    """Request to compare multiple contracts"""
    contract_ids: List[int] = Field(..., min_length=2, max_length=5)


class ContractCompareResponse(BaseModel):
    """Comparison results"""
    contracts: List[ContractResponse]
    comparison: dict  # Side-by-side comparison data
    recommendation: str  # AI recommendation


# ==================== Vehicle Schemas ====================

class VINLookupResponse(BaseModel):
    """Response from VIN lookup"""
    vin: str
    make: Optional[str]
    model: Optional[str]
    year: Optional[int]
    trim: Optional[str]
    body_type: Optional[str]
    engine: Optional[str]
    transmission: Optional[str]
    drivetrain: Optional[str]
    fuel_type: Optional[str]
    recalls: Optional[List[dict]] = None
    estimated_value: Optional[float] = None
    source: str = "NHTSA"
    
    # New Pricing & Metadata fields
    msrp: Optional[float] = None
    market_average: Optional[float] = None
    fair_price_low: Optional[float] = None
    fair_price_high: Optional[float] = None
    incentives: Optional[List[str]] = None
    data_sources: Optional[List[str]] = Field(default_factory=lambda: ["NHTSA"])
    timestamp: str = Field(default_factory=lambda: datetime.utcnow().isoformat())
    confidence_indicators: Optional[dict] = None


class PriceEstimateRequest(BaseModel):
    """Request for price estimation"""
    make: str
    model: str
    year: int
    mileage: Optional[int] = None
    trim: Optional[str] = None
    condition: Optional[str] = "good"  # excellent, good, fair, poor


class PriceEstimateResponse(BaseModel):
    """Price estimation result"""
    make: str
    model: str
    year: int
    estimated_value_low: float
    estimated_value_high: float
    estimated_value_avg: float
    confidence: str  # high, medium, low
    source: str
    notes: Optional[str] = None


# ==================== Negotiation Schemas ====================

class ChatMessage(BaseModel):
    """Single chat message"""
    role: str = Field(..., pattern="^(user|assistant|system)$")
    content: str
    timestamp: Optional[datetime] = None


class NegotiationChatRequest(BaseModel):
    """Request for negotiation chat"""
    message: str
    contract_id: Optional[int] = None
    session_id: Optional[str] = None
    context: Optional[dict] = None  # Additional context (SLA data, vehicle info)


class NegotiationChatResponse(BaseModel):
    """Response from negotiation chat"""
    session_id: str
    response: str
    suggested_actions: Optional[List[str]] = None
    negotiation_points: Optional[List[str]] = None


class GenerateEmailRequest(BaseModel):
    """Request to generate negotiation email"""
    contract_id: int
    email_type: str = Field(..., pattern="^(initial_offer|counter_offer|question|final_offer)$")
    specific_points: Optional[List[str]] = None
    tone: str = "professional"  # professional, firm, friendly


class GenerateEmailResponse(BaseModel):
    """Generated email response"""
    subject: str
    body: str
    key_points: List[str]


# ==================== Analysis Schemas ====================

class AnalyzeContractRequest(BaseModel):
    """Request to analyze raw contract text"""
    text: str = Field(..., min_length=100)
    contract_type: Optional[str] = None  # lease, loan


class QuickAnalysisResponse(BaseModel):
    """Quick analysis without saving to database"""
    sla_data: SLAData
    fairness_score: int
    fairness_explanation: str
    red_flags: List[str]
    confidence_score: int
