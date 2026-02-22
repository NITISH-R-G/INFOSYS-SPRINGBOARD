"""
Pydantic Schemas for API Request/Response validation
"""
from datetime import datetime
from typing import Optional, List, Any, Union, Dict
from pydantic import BaseModel, EmailStr, Field


# ==================== Auth Schemas ====================

class UserCreate(BaseModel):
    """Schema for user registration"""
    email: EmailStr
    full_name: str = Field(..., min_length=2, max_length=255)
    password: str = Field(..., min_length=8)
    role: str = Field(default="buyer", pattern="^(buyer|dealer|admin)$")


class UserLogin(BaseModel):
    """Schema for user login"""
    email: EmailStr
    password: str


class UserResponse(BaseModel):
    """Schema for user response (without password)"""
    id: int
    email: str
    full_name: str
    role: str
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
    role: Optional[str] = None


# ==================== Messaging Schemas ====================

class ConversationCreate(BaseModel):
    dealer_id: int
    contract_id: Optional[int] = None
    subject: Optional[str] = None

class MessageCreate(BaseModel):
    content: str

class MessageResponse(BaseModel):
    id: int
    conversation_id: int
    sender_id: int
    content: str
    is_read: bool
    created_at: datetime
    
    class Config:
        from_attributes = True

class ConversationResponse(BaseModel):
    id: int
    buyer_id: int
    dealer_id: int
    contract_id: Optional[int] = None
    subject: Optional[str] = None
    created_at: datetime
    updated_at: datetime
    messages: Optional[List[MessageResponse]] = None
    
    class Config:
        from_attributes = True


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

class SectionDealerInformation(BaseModel):
    """Extracted shadow profile data for the dealer"""
    dealer_name: str = "Not Mentioned"
    contact_email: str = "Not Mentioned"
    contact_phone: str = "Not Mentioned"
    risk_flags: List[ReviewRisk] = []

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
    dealer_information: Optional[SectionDealerInformation] = None
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
    risk_assessment: Optional[Dict[str, Any]] = None  # Gap 5: Structured risk assessment


class ContractUploadResponse(BaseModel):
    """Response after contract upload"""
    id: int
    filename: str
    status: str
    raw_text: Optional[str] = None
    message: str


class DealerResponse(BaseModel):
    """Dealer response schema"""
    id: int
    name: str
    email: Optional[str] = None
    phone: Optional[str] = None
    user_id: Optional[int] = None
    is_claimed: bool
    
    class Config:
        from_attributes = True


class ContractResponse(BaseModel):
    """Full contract response with analysis"""
    id: int
    filename: str
    contract_type: Optional[str]
    status: str
    raw_text: Optional[str]
    dealer_id: Optional[int]
    dealer: Optional[DealerResponse] = None
    sla_data: Optional[dict]
    detailed_analysis: Optional[DetailedAnalysis] = None  # Sprint 9 addition
    risk_assessment: Optional[dict] = None  # Gap 5: Structured risk report
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


# ==================== Risk Assessment Schemas (Gap 5) ====================

class RiskItem(BaseModel):
    """Individual risk item with benchmark comparison"""
    category: str = Field(..., description="Risk category, e.g. 'Interest Rate (APR)'")
    severity: str = Field(..., description="high, medium, or low")
    benchmark: str = Field(..., description="Industry benchmark for comparison")
    actual_value: str = Field(..., description="Actual value from the contract")
    impact_points: int = Field(..., description="Score impact in points")
    mitigation: str = Field(..., description="Actionable advice to mitigate the risk")


class RiskAssessmentResult(BaseModel):
    """Structured risk assessment report"""
    overall_risk_level: str = Field(..., description="high, medium, or low")
    risk_items: List[RiskItem] = Field(default_factory=list)
    total_impact_points: int = Field(0, description="Total score impact")
    summary: str = Field(..., description="Human-readable risk summary")


# ==================== Audit Trail Schemas (Gap 9) ====================

class AuditLogResponse(BaseModel):
    """Audit log entry response"""
    id: int
    user_id: Optional[int]
    action: str
    entity_type: Optional[str]
    entity_id: Optional[int]
    details: Optional[dict]
    ip_address: Optional[str]
    created_at: datetime

    class Config:
        from_attributes = True


# ==================== Price Recommendation Schemas (Gap 3) ====================

class PriceRecommendationResponse(BaseModel):
    """Structured price recommendation with fair price range"""
    fair_price_low: float
    fair_price_high: float
    msrp: Optional[float] = None
    estimated_avg: float
    basis: str = Field(..., description="Data basis, e.g. 'Algorithmic estimate based on depreciation, mileage, and segment'")
    methodology: str = Field(..., description="Explanation of how the range was calculated")
    confidence: str
    vehicle_summary: str


# ==================== Negotiation Strategy Schemas (Gap 13 & 15) ====================

class StatusUpdateRequest(BaseModel):
    """Request to update contract workflow status"""
    status: str = Field(..., pattern="^(review|analysis|counter_offer|finalized)$")


class NegotiationStrategyResponse(BaseModel):
    """Structured negotiation strategy from AI"""
    priority_actions: List[str] = Field(default_factory=list, description="Top priority negotiation actions")
    counter_offer_points: List[dict] = Field(default_factory=list, description="Specific counter-offer suggestions")
    talking_points: List[str] = Field(default_factory=list, description="Key talking points for the dealer")
    what_if_scenarios: List[dict] = Field(default_factory=list, description="What-if scenario analyses")
    overall_strategy: str = Field(..., description="Summary of recommended negotiation approach")

