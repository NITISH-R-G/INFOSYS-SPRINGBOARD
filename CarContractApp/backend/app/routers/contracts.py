"""
Contracts Router
Handles contract upload, OCR processing, and AI analysis
"""
import shutil
import os
import json
import uuid
from datetime import datetime
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, status
from sqlalchemy.orm import Session

from ..database import get_db, Contract, Vehicle
from ..config import settings
from ..models.schemas import (
    ContractUploadResponse, ContractResponse, ContractAnalysisResult,
    AnalyzeContractRequest, QuickAnalysisResponse, ContractCompareRequest,
    ContractCompareResponse
)
from ..services.ocr_service import ocr_service, OCRException
from ..services.llm_service import llm_service, LLMException
from ..services.vin_service import vin_service, VINException
from ..services.price_service import price_service
from ..services.scoring_engine import ScoringEngine

router = APIRouter(prefix="/contracts", tags=["Contracts"])

# Default user ID for non-authenticated usage
DEFAULT_USER_ID = 1


def _ensure_upload_dir():
    """Ensure upload directory exists"""
    os.makedirs(settings.UPLOAD_DIR, exist_ok=True)


@router.post("/upload", response_model=ContractUploadResponse)
async def upload_contract(
    file: UploadFile = File(...),
    db: Session = Depends(get_db)
):
    """
    Upload a contract document (PDF or image)
    
    Returns the uploaded contract ID and extracted text
    """
    # Validate file extension
    ext = os.path.splitext(file.filename)[1].lower()
    if ext not in settings.ALLOWED_EXTENSIONS:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"File type not allowed. Allowed: {settings.ALLOWED_EXTENSIONS}"
        )
    
    # Read file contents
    contents = await file.read()
    
    # Check file size
    if len(contents) > settings.MAX_UPLOAD_SIZE_MB * 1024 * 1024:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"File too large. Max size: {settings.MAX_UPLOAD_SIZE_MB}MB"
        )
    
    # Save file
    _ensure_upload_dir()
    file_id = str(uuid.uuid4())
    file_path = os.path.join(settings.UPLOAD_DIR, f"{file_id}{ext}")
    
    with open(file_path, "wb") as f:
        f.write(contents)
    
    # Extract text using OCR
    try:
        raw_text, file_type = ocr_service.extract_text(contents, file.filename)
    except OCRException as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )
    
    # Create database record
    db_contract = Contract(
        user_id=DEFAULT_USER_ID,
        filename=file.filename,
        file_path=file_path,
        file_type=file_type,
        raw_text=raw_text,
        status="uploaded"
    )
    
    db.add(db_contract)
    db.commit()
    db.refresh(db_contract)
    
    return ContractUploadResponse(
        id=db_contract.id,
        filename=file.filename,
        status="uploaded",
        raw_text=raw_text[:1000] + "..." if len(raw_text) > 1000 else raw_text,
        message="Contract uploaded successfully. Call /contracts/{id}/analyze to extract SLA data."
    )


@router.post("/{contract_id}/analyze", response_model=ContractResponse)
async def analyze_contract(
    contract_id: int,
    db: Session = Depends(get_db)
):
    """
    Analyze an uploaded contract using AI
    
    Extracts SLA data, calculates fairness score, and identifies red flags
    """
    # Get contract
    contract = db.query(Contract).filter(
        Contract.id == contract_id
    ).first()
    
    if not contract:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Contract not found"
        )
    
    if not contract.raw_text:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Contract has no extracted text. Please re-upload."
        )
    
    # Update status
    contract.status = "processing"
    db.commit()
    
    try:
        # Analyze with LLM
        result = await llm_service.analyze_contract(
            contract.raw_text,
            contract.contract_type
        )
        
        # Update contract with results
        contract.sla_data = result.sla_data.model_dump()
        contract.fairness_score = result.fairness_score
        contract.fairness_explanation = result.fairness_explanation
        
        # Save detailed 12-section analysis (Sprint 9)
        if result.detailed_analysis:
            contract.detailed_analysis = result.detailed_analysis.model_dump()
        
        # Process red flags to add coordinates
        processed_red_flags = []
        file_bytes = None
        
        # We need the file bytes for coordinate extraction
        if os.path.exists(contract.file_path):
            with open(contract.file_path, "rb") as f:
                file_bytes = f.read()
        
        for flag in result.red_flags:
            flag_dict = flag.model_dump() if hasattr(flag, 'model_dump') else flag
            
            # Find coordinates if we have the file and clause text
            if file_bytes and flag_dict.get("clause_text"):
                coords = ocr_service.get_text_coordinates(file_bytes, flag_dict["clause_text"])
                flag_dict["coordinates"] = coords
            
            processed_red_flags.append(flag_dict)

        contract.red_flags = processed_red_flags
        contract.confidence_score = result.confidence_score
        contract.contract_type = result.contract_type
        
        # Auto-extract and lookup VIN
        vin_lookup_result = None
        try:
            extracted_vin = vin_service.extract_vin_from_text(contract.raw_text)
            if extracted_vin:
                # Perform NHTSA lookup
                vin_data = await vin_service.get_full_vehicle_info(extracted_vin)
                
                # Cross-check with contract
                cross_check = vin_service.cross_check_with_contract(
                    vin_data, contract.raw_text
                )
                
                # ---------------------------------------------------------
                # FINANCIAL INTELLIGENCE: Market Value Analysis
                # ---------------------------------------------------------
                price_estimate = None
                if vin_data and vin_data.make and vin_data.model and vin_data.year:
                    # Helper for mileage extraction (simple regex or use what LLM found if mapped)
                    # For now using SLA data if available
                    mileage_val = result.sla_data.mileage_limit if result.sla_data.mileage_limit else None
                    
                    price_estimate = await price_service.estimate_price(
                        make=vin_data.make,
                        model=vin_data.model,
                        year=vin_data.year,
                        mileage=mileage_val
                    )
                    
                    # Update SLA Data with Market Value
                    if price_estimate:
                        contract.sla_data["market_value"] = price_estimate["estimated_value_avg"]
                        contract.sla_data["market_value_high"] = price_estimate["estimated_value_high"]
                        contract.sla_data["market_value_low"] = price_estimate["estimated_value_low"]
                        contract.sla_data["market_confidence"] = price_estimate["confidence"]
                        
                        # Recalculate Fairness Score with Market Data
                        # We need to re-convert dict to object for ScoringEngine
                        from ..models.schemas import SLAData, RedFlag
                        updated_sla = SLAData(**contract.sla_data)
                        current_flags = [RedFlag(**rf) for rf in result.red_flags]
                        
                        new_score, new_explanation = ScoringEngine.calculate_score(
                            sla=updated_sla, 
                            risks=current_flags,
                            contract_type=contract.contract_type
                        )
                        
                        contract.fairness_score = new_score
                        contract.fairness_explanation = new_explanation
                        # Appending market note to explanation
                        if "Market Value" in new_explanation or "price" in new_explanation.lower():
                             contract.fairness_explanation += f" (Est. Market Value: ${price_estimate['estimated_value_avg']:,.0f})"

                vin_lookup_result = {
                    "vin_status": "Valid",
                    "vin_number": extracted_vin,
                    "vehicle_details": vin_data,
                    "cross_check": cross_check,
                    "estimated_value": price_estimate["estimated_value_avg"] if price_estimate else None
                }
                
                # Add mismatch warning to red flags if detected
                if cross_check.get("mismatch_detected"):
                    processed_red_flags.append({
                        "clause_text": f"VIN: {extracted_vin}",
                        "title": "Vehicle Data Mismatch",
                        "risk_level": "medium",
                        "why_flag": "Decoded VIN data doesn't match contract details",
                        "risks": "; ".join(cross_check.get("mismatch_details", [])),
                        "plain_explanation": "The vehicle information in the contract may not match the actual vehicle.",
                        "suggestion": "Verify vehicle make, model, and year match the VIN before signing."
                    })
                    contract.red_flags = processed_red_flags
        except VINException:
            vin_lookup_result = {"vin_status": "Invalid", "vin_number": None}
        except Exception as e:
            print(f"Error in VIN/Price analysis: {e}")
            vin_lookup_result = {"vin_status": "Lookup Failed", "vin_number": None}
        
        contract.status = "analyzed"
        contract.analyzed_at = datetime.utcnow()
        
        db.commit()
        db.refresh(contract)
        
        return _contract_to_response(contract, vin_lookup_result)
        
    except LLMException as e:
        contract.status = "error"
        contract.error_message = str(e)
        db.commit()
        
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Analysis failed: {str(e)}"
        )


@router.get("/{contract_id}", response_model=ContractResponse)
async def get_contract(
    contract_id: int,
    db: Session = Depends(get_db)
):
    """
    Get a contract by ID with analysis results
    """
    contract = db.query(Contract).filter(
        Contract.id == contract_id
    ).first()
    
    if not contract:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Contract not found"
        )
    
    return _contract_to_response(contract)


@router.get("/", response_model=List[ContractResponse])
async def list_contracts(
    skip: int = 0,
    limit: int = 20,
    db: Session = Depends(get_db)
):
    """
    List all contracts
    """
    contracts = db.query(Contract).order_by(
        Contract.created_at.desc()
    ).offset(skip).limit(limit).all()
    
    return [_contract_to_response(c) for c in contracts]


@router.delete("/{contract_id}")
async def delete_contract(
    contract_id: int,
    db: Session = Depends(get_db)
):
    """
    Delete a contract
    """
    contract = db.query(Contract).filter(
        Contract.id == contract_id
    ).first()
    
    if not contract:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Contract not found"
        )
    
    # Delete file if exists
    if contract.file_path and os.path.exists(contract.file_path):
        os.remove(contract.file_path)
    
    db.delete(contract)
    db.commit()
    
    return {"message": "Contract deleted successfully"}


@router.post("/analyze-text", response_model=QuickAnalysisResponse)
async def analyze_text(
    request: AnalyzeContractRequest
):
    """
    Quick analysis without saving to database
    
    Useful for testing or one-off analysis
    """
    try:
        result = await llm_service.analyze_contract(
            request.text,
            request.contract_type
        )
        
        return QuickAnalysisResponse(
            sla_data=result.sla_data,
            fairness_score=result.fairness_score,
            fairness_explanation=result.fairness_explanation,
            red_flags=result.red_flags,
            confidence_score=result.confidence_score
        )
        
    except LLMException as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Analysis failed: {str(e)}"
        )


@router.post("/compare", response_model=ContractCompareResponse)
async def compare_contracts(
    request: ContractCompareRequest,
    db: Session = Depends(get_db)
):
    """
    Compare multiple contracts side-by-side
    """
    # Fetch all contracts
    contracts = db.query(Contract).filter(
        Contract.id.in_(request.contract_ids)
    ).all()
    
    if len(contracts) != len(request.contract_ids):
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="One or more contracts not found"
        )
    
    # Check all are analyzed
    for c in contracts:
        if c.status != "analyzed":
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Contract {c.id} has not been analyzed yet"
            )
    
    # Build comparison
    comparison = _build_comparison(contracts)
    recommendation = _generate_recommendation(contracts)
    
    return ContractCompareResponse(
        contracts=[_contract_to_response(c) for c in contracts],
        comparison=comparison,
        recommendation=recommendation
    )


def _contract_to_response(contract: Contract, vin_lookup: Optional[dict] = None) -> ContractResponse:
    """Convert contract model to response schema"""
    vehicle_data = None
    if contract.vehicle:
        vehicle_data = {
            "vin": contract.vehicle.vin,
            "make": contract.vehicle.make,
            "model": contract.vehicle.model,
            "year": contract.vehicle.year,
        }
    
    return ContractResponse(
        id=contract.id,
        filename=contract.filename,
        contract_type=contract.contract_type,
        status=contract.status,
        raw_text=contract.raw_text[:500] + "..." if contract.raw_text and len(contract.raw_text) > 500 else contract.raw_text,
        sla_data=contract.sla_data,
        detailed_analysis=contract.detailed_analysis,  # Sprint 9: 12-section analysis
        fairness_score=contract.fairness_score,
        fairness_explanation=contract.fairness_explanation,
        red_flags=contract.red_flags,
        confidence_score=contract.confidence_score,
        created_at=contract.created_at,
        analyzed_at=contract.analyzed_at,
        vehicle=vehicle_data,
        vin_lookup=vin_lookup
    )


def _build_comparison(contracts: List[Contract]) -> dict:
    """Build side-by-side comparison of contract terms"""
    comparison = {
        "apr": {},
        "monthly_payment": {},
        "term_months": {},
        "mileage_limit": {},
        "fairness_score": {},
        "red_flag_count": {},
    }
    
    for c in contracts:
        key = f"contract_{c.id}"
        sla = c.sla_data or {}
        
        comparison["apr"][key] = sla.get("apr")
        comparison["monthly_payment"][key] = sla.get("monthly_payment")
        comparison["term_months"][key] = sla.get("term_months")
        comparison["mileage_limit"][key] = sla.get("mileage_limit")
        comparison["fairness_score"][key] = c.fairness_score
        comparison["red_flag_count"][key] = len(c.red_flags or [])
    
    return comparison


def _generate_recommendation(contracts: List[Contract]) -> str:
    """Generate a recommendation based on comparison"""
    # Simple logic: recommend the one with highest fairness score
    best = max(contracts, key=lambda c: c.fairness_score or 0)
    
    if not best.fairness_score:
        return "Unable to determine best contract. Please review the details manually."
    
    if best.fairness_score >= 80:
        return f"Contract {best.id} ({best.filename}) appears to be the best option with a fairness score of {best.fairness_score}/100."
    elif best.fairness_score >= 60:
        return f"Contract {best.id} ({best.filename}) has the highest fairness score ({best.fairness_score}/100), but consider negotiating the red flags."
    else:
        return f"All contracts have concerning fairness scores. Consider negotiating better terms or exploring other options."
