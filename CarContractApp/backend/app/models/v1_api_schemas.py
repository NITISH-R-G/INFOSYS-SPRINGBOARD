from typing import Optional, Dict, Any, List
from pydantic import BaseModel, Field
from datetime import datetime

class FullAnalysisRequest(BaseModel):
    """Payload for the unified analysis endpoint."""
    contract_text: str = Field(..., description="The OCR extracted text from the contract document.")

class VehicleSpecs(BaseModel):
    vin: str
    make: Optional[str] = None
    model: Optional[str] = None
    year: Optional[int] = None
    trim: Optional[str] = None
    body_type: Optional[str] = None
    engine: Optional[str] = None

class RecallAlert(BaseModel):
    campaign_number: Optional[str] = None
    component: Optional[str] = None
    summary: Optional[str] = None
    remedy: Optional[str] = None

class SynthesizedAnalysisResponse(BaseModel):
    """Aggregated response containing OCR terms, VIN specs, Pricing, and Fairness."""
    # 1. Contract Details
    contract_type: str = "Unknown"
    apr: Optional[float] = None
    monthly_payment: Optional[float] = None
    term_months: Optional[int] = None
    total_financed: Optional[float] = None
    
    # 2. Vehicle Details
    vehicle_specs: Optional[VehicleSpecs] = None
    active_recalls: List[RecallAlert] = []
    
    # 3. Pricing Aggregation
    fair_price_low: Optional[float] = None
    fair_price_high: Optional[float] = None
    estimated_msrp: Optional[float] = None
    market_average: Optional[float] = None
    pricing_sources: List[str] = []
    
    # 4. Synthesized Score
    contract_fairness_score: int = Field(0, description="0-100 Score combining all factors")
    fairness_tier: str = "Unknown"
    analysis_notes: str = ""
    timestamp: datetime = Field(default_factory=datetime.utcnow)
