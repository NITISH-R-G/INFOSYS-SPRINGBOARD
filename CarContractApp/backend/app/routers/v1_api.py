import logging
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
import hashlib
import json

from ..database import get_db, User
from ..services.auth_service import get_current_active_user
from ..models.v1_api_schemas import (
    FullAnalysisRequest, 
    SynthesizedAnalysisResponse, 
    VehicleSpecs, 
    RecallAlert
)
from ..services.llm_service import llm_service
from ..services.vin_service import vin_service
from ..services.price_service import price_service
from ..services.scoring_engine import ScoringEngine

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/v1", tags=["Analysis"])

# Simple in-memory cache for deterministic responses
_analysis_cache = {}

@router.post("/contract-analysis", response_model=SynthesizedAnalysisResponse)
async def full_contract_analysis(
    request: FullAnalysisRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """
    Unified endpoint for full-stack data integration.
    1. Extracts contract text via Gemini.
    2. Decodes VIN and fetches active Recalls via NHTSA.
    3. Aggregates real-world pricing via Edmunds, TrueCar, AutoTrader.
    4. Computes a deterministic Fairness Score.
    """
    logger.info(f"User {current_user.id} requested full contract analysis.")
    
    # 0. Deterministic Hashing
    doc_hash = hashlib.sha256(request.contract_text.encode('utf-8')).hexdigest()
    if doc_hash in _analysis_cache:
        logger.info(f"Returning cached deterministic result for document hash: {doc_hash}")
        return _analysis_cache[doc_hash]
    
    # 1. LLM Extraction
    try:
        llm_result = await llm_service.analyze_contract(request.contract_text)
    except Exception as e:
        logger.error(f"LLM Extraction failed: {e}")
        raise HTTPException(status_code=500, detail=f"AI Extraction failed: {str(e)}")

    sla_data = llm_result.sla_data
    vehicle_details = llm_result.detailed_analysis.get("vehicle_details", {})
    
    vin = vehicle_details.get("vin")
    raw_make = vehicle_details.get("make")
    raw_model = vehicle_details.get("model")
    raw_year = vehicle_details.get("manufacturing_year")
    
    if raw_year and str(raw_year).isdigit():
        year = int(raw_year)
    else:
        year = 2020  # Default fallback if LLM fails to extract

    # Try to validate and extract via Regex if LLM missed it
    if not vin or vin.lower() == "not mentioned":
        vin = vin_service.extract_vin_from_text(request.contract_text)
        
    vin_specs = None
    recalls = []
    
    # 2. VIN Decode & Recalls (NHTSA)
    if vin and vin_service._validate_vin(vin):
        try:
            vin_data = await vin_service.decode_vin(vin)
            vin_specs = VehicleSpecs(
                vin=vin_data.get("vin", vin),
                make=vin_data.get("make", raw_make),
                model=vin_data.get("model", raw_model),
                year=vin_data.get("year", year),
                trim=vin_data.get("trim"),
                body_type=vin_data.get("body_type"),
                engine=vin_data.get("engine")
            )
            # Update local variables for pricing
            raw_make = vin_specs.make or raw_make
            raw_model = vin_specs.model or raw_model
            year = vin_specs.year or year
            
            # Fetch recalls
            fetched_recalls = await vin_service.get_recalls(raw_make, raw_model, year)
            for r in fetched_recalls:
                recalls.append(RecallAlert(
                    campaign_number=r.get("campaign_number"),
                    component=r.get("component"),
                    summary=r.get("summary"),
                    remedy=r.get("remedy")
                ))
                
        except Exception as e:
            logger.warning(f"VIN Decode or Recall fetch failed: {e}")

    # Fallback to LLM details if VIN decode failed entirely
    if not vin_specs:
        vin_specs = VehicleSpecs(
            vin=vin or "Unknown",
            make=raw_make,
            model=raw_model,
            year=year
        )

    # 3. Pricing Aggregation
    pricing_data = {}
    if raw_make and raw_model and year:
        try:
            pricing_data = await price_service.generate_recommendation(
                make=raw_make,
                model=raw_model,
                year=year
            )
        except Exception as e:
            logger.warning(f"Pricing aggregation failed: {e}")

    # 4. Scoring Engine
    contract_type = "lease" if "lease" in str(llm_result.detailed_analysis.get("contract_type", "")).lower() else "loan"
    score, explanation = ScoringEngine.calculate_score(
        sla=sla_data,
        contract_type=contract_type,
        dcfs_features=llm_result.dcfs_features
    )
    
    # Determine Fairness Tier
    if score >= 90:
        tier = "Excellent"
    elif score >= 70:
        tier = "Good"
    elif score >= 50:
        tier = "Fair"
    else:
        tier = "Poor"

    
    response = SynthesizedAnalysisResponse(
        contract_type=contract_type.capitalize(),
        apr=sla_data.apr,
        monthly_payment=sla_data.monthly_payment,
        term_months=sla_data.term_months,
        total_financed=sla_data.loan_amount,
        
        vehicle_specs=vin_specs,
        active_recalls=recalls[:5], # Limit to top 5
        
        fair_price_low=pricing_data.get("fair_price_low"),
        fair_price_high=pricing_data.get("fair_price_high"),
        estimated_msrp=pricing_data.get("msrp"),
        market_average=pricing_data.get("estimated_avg"),
        pricing_sources=pricing_data.get("data_sources", []),
        
        contract_fairness_score=score,
        fairness_tier=tier,
        analysis_notes=explanation
    )
    
    # Store in memory cache
    _analysis_cache[doc_hash] = response
    return response
