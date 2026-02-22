"""
Contracts Router
Handles contract upload, OCR processing, and AI analysis
Uses typed exceptions and writes to normalized tables.
"""
import shutil
import os
import json
import uuid
import logging
from datetime import datetime
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, status, Request
from sqlalchemy.orm import Session

from ..database import get_db, Contract, ContractFile, ContractPage, ContractSLA, ExtractedClause, Vehicle, User, Dealer
from ..services.auth_service import get_current_active_user, get_password_hash
from ..config import settings
from ..models.schemas import (
    ContractUploadResponse, ContractResponse, ContractAnalysisResult,
    AnalyzeContractRequest, QuickAnalysisResponse, ContractCompareRequest,
    ContractCompareResponse, StatusUpdateRequest
)
from ..services.ocr_service import ocr_service, OCRException
from ..services.llm_service import llm_service, LLMException
from ..services.vin_service import vin_service, VINException
from ..services.price_service import price_service
from ..services.scoring_engine import ScoringEngine
from ..exceptions import (
    OCRProcessingError, LLMAnalysisError, ContractNotFoundError, ValidationError
)
from ..services.audit_service import log_event, get_client_ip, AuditAction

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/contracts", tags=["Contracts"])


def _ensure_upload_dir():
    """Ensure upload directory exists"""
    os.makedirs(settings.UPLOAD_DIR, exist_ok=True)


@router.post("/upload", response_model=ContractUploadResponse)
async def upload_contract(
    request: Request,
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """
    Upload a contract document (PDF or image)
    
    Returns the uploaded contract ID and extracted text.
    Files are saved to the normalized contract_files / contract_pages tables.
    """
    # Validate file extension
    ext = os.path.splitext(file.filename)[1].lower()
    if ext not in settings.ALLOWED_EXTENSIONS:
        raise ValidationError(
            detail=f"File type not allowed. Allowed: {settings.ALLOWED_EXTENSIONS}"
        )
    
    # Read file contents
    contents = await file.read()
    
    # Check file size
    if len(contents) > settings.MAX_UPLOAD_SIZE_MB * 1024 * 1024:
        raise ValidationError(
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
        logger.error(f"OCR extraction failed for {file.filename}: {e}")
        raise OCRProcessingError(detail=str(e))
    
    # Create contract record
    db_contract = Contract(
        user_id=current_user.id,
        raw_text=raw_text,
        status="uploaded"
    )
    db.add(db_contract)
    db.flush()  # Get the contract ID
    
    # Create contract_file record
    db_file = ContractFile(
        contract_id=db_contract.id,
        filename=file.filename,
        file_path=file_path,
        file_type=file_type,
        file_size_bytes=len(contents)
    )
    db.add(db_file)
    
    db.commit()
    db.refresh(db_contract)

    # --- Gap 9: Audit Trail ---
    log_event(
        db=db,
        user_id=current_user.id,
        action=AuditAction.CONTRACT_UPLOADED,
        entity_type="contract",
        entity_id=db_contract.id,
        details={
            "filename": file.filename,
            "file_type": file_type,
            "file_size_bytes": len(contents),
            "text_length": len(raw_text)
        },
        ip_address=get_client_ip(request)
    )
    db.commit()
    
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
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """
    Analyze an uploaded contract using AI
    
    Extracts SLA data, calculates fairness score, and identifies red flags.
    Results are saved to contract_sla and extracted_clauses tables.
    """
    # Get contract
    contract = db.query(Contract).filter(
        Contract.id == contract_id,
        Contract.user_id == current_user.id
    ).first()
    
    if not contract:
        raise ContractNotFoundError(contract_id=contract_id)
    
    if not contract.raw_text:
        raise ValidationError(detail="Contract has no extracted text. Please re-upload.")
    
    # Update status
    contract.status = "processing"
    db.commit()

    # --- Gap 9: Audit Trail — analysis started ---
    log_event(
        db=db,
        user_id=current_user.id,
        action=AuditAction.LLM_ANALYSIS_STARTED,
        entity_type="contract",
        entity_id=contract.id,
        details={"contract_type": contract.contract_type}
    )
    db.commit()
    
    try:
        # Analyze with LLM
        result = await llm_service.analyze_contract(
            contract.raw_text,
            contract.contract_type
        )
        
        # Save to contract_sla table
        sla_data = result.sla_data
        db_sla = db.query(ContractSLA).filter(ContractSLA.contract_id == contract.id).first()
        if db_sla:
            # Update existing SLA
            for field in ['apr', 'term_months', 'monthly_payment', 'down_payment',
                          'residual_value', 'mileage_limit', 'mileage_overage_fee',
                          'early_termination_fee', 'buyout_price', 'maintenance_included',
                          'warranty_months', 'documentation_fee', 'acquisition_fee',
                          'disposition_fee']:
                setattr(db_sla, field, getattr(sla_data, field, None))
        else:
            db_sla = ContractSLA(
                contract_id=contract.id,
                currency_code=getattr(sla_data, 'currency_code', 'USD') or 'USD',
                apr=sla_data.apr,
                term_months=sla_data.term_months,
                monthly_payment=sla_data.monthly_payment,
                down_payment=sla_data.down_payment,
                residual_value=sla_data.residual_value,
                mileage_limit=sla_data.mileage_limit,
                mileage_overage_fee=sla_data.mileage_overage_fee,
                early_termination_fee=sla_data.early_termination_fee,
                buyout_price=sla_data.buyout_price,
                maintenance_included=sla_data.maintenance_included,
                warranty_months=sla_data.warranty_months,
            )
            db.add(db_sla)
        
        # Update contract main record
        contract.fairness_score = result.fairness_score
        contract.fairness_explanation = result.fairness_explanation
        contract.confidence_score = result.confidence_score
        contract.contract_type = result.contract_type
        
        # Save detailed 12-section analysis
        if result.detailed_analysis:
            detailed_dict = result.detailed_analysis.model_dump()
        else:
            detailed_dict = {}

        # --- Gap 5: Structured Risk Assessment ---
        vehicle_year = None
        if contract.vehicle and contract.vehicle.year:
            vehicle_year = contract.vehicle.year

        risk_assessment = ScoringEngine.assess_risk(
            sla=sla_data,
            risks=[rf for rf in result.red_flags if hasattr(rf, 'risk_level')],
            contract_type=result.contract_type or "loan",
            vehicle_year=vehicle_year
        )
        detailed_dict["risk_assessment"] = risk_assessment
        contract.detailed_analysis = detailed_dict

        # --- Gap 9: Shadow Profile Creation ---
        dealer_info = detailed_dict.get("dealer_information")
        if dealer_info:
            dealer_email = dealer_info.get("contact_email")
            dealer_name = dealer_info.get("dealer_name")
            dealer_phone = dealer_info.get("contact_phone")
            
            # Use a strict check to avoid spamming "Not Mentioned" emails
            if dealer_email and dealer_email.lower() != "not mentioned" and "@" in dealer_email:
                dealer_email = dealer_email.lower().strip()
                
                # Check if dealer user already exists
                existing_user = db.query(User).filter(User.email == dealer_email).first()
                if not existing_user:
                    # 1. Create Shadow User
                    shadow_user = User(
                        email=dealer_email,
                        full_name=dealer_name if dealer_name != "Not Mentioned" else "Unknown Dealer",
                        role="dealer",
                        hashed_password=get_password_hash(str(uuid.uuid4()))  # Secure random temp pass
                    )
                    if dealer_phone != "Not Mentioned":
                        shadow_user.phone_number = dealer_phone
                    db.add(shadow_user)
                    db.flush()
                    user_id_to_link = shadow_user.id
                else:
                    user_id_to_link = existing_user.id
                
                # Check if dealer profile exists by user_id
                existing_dealer = db.query(Dealer).filter(Dealer.user_id == user_id_to_link).first()
                if not existing_dealer:
                    # 2. Create Dealer Profile linked to User
                    shadow_dealer = Dealer(
                        name=dealer_name if dealer_name != "Not Mentioned" else "Unknown Dealer",
                        email=dealer_email,
                        phone=dealer_phone if dealer_phone != "Not Mentioned" else None,
                        is_claimed=False,
                        user_id=user_id_to_link
                    )
                    db.add(shadow_dealer)
                    db.flush()
                    
                    # 3. Link Contract to Dealer Profile
                    contract.dealer_id = shadow_dealer.id
                else:
                    # Link existing dealer
                    contract.dealer_id = existing_dealer.id
        
        # Process red flags → save to extracted_clauses table
        processed_red_flags = []
        file_bytes = None
        
        # Get file bytes for coordinate extraction
        contract_file = db.query(ContractFile).filter(
            ContractFile.contract_id == contract.id
        ).first()
        
        if contract_file and os.path.exists(contract_file.file_path):
            with open(contract_file.file_path, "rb") as f:
                file_bytes = f.read()
        
        for flag in result.red_flags:
            flag_dict = flag.model_dump() if hasattr(flag, 'model_dump') else flag
            
            # Find coordinates if available
            coords = None
            if file_bytes and flag_dict.get("clause_text"):
                coords = ocr_service.get_text_coordinates(file_bytes, flag_dict["clause_text"])
                flag_dict["coordinates"] = coords
            
            processed_red_flags.append(flag_dict)
            
            # Save to extracted_clauses
            db_clause = ExtractedClause(
                contract_id=contract.id,
                section_key=flag_dict.get("title", "unknown").lower().replace(" ", "_"),
                section_title=flag_dict.get("title", "Unknown"),
                clause_text=flag_dict.get("clause_text", ""),
                risk_level=flag_dict.get("risk_level", "medium"),
                risk_reason=flag_dict.get("why_flag", ""),
                suggestion=flag_dict.get("suggestion", ""),
                coordinates=coords
            )
            db.add(db_clause)

        contract.red_flags = processed_red_flags
        
        # Auto-extract and lookup VIN
        vin_lookup_result = None
        try:
            extracted_vin = vin_service.extract_vin_from_text(contract.raw_text)
            if extracted_vin:
                vin_data = await vin_service.get_full_vehicle_info(extracted_vin)
                cross_check = vin_service.cross_check_with_contract(
                    vin_data, contract.raw_text
                )
                
                # Financial intelligence: Market Value Analysis
                price_estimate = None
                if vin_data and vin_data.make and vin_data.model and vin_data.year:
                    mileage_val = sla_data.mileage_limit if sla_data.mileage_limit else None
                    price_estimate = await price_service.estimate_price(
                        make=vin_data.make,
                        model=vin_data.model,
                        year=vin_data.year,
                        mileage=mileage_val
                    )
                    
                    # Update SLA with market value
                    if price_estimate and db_sla:
                        db_sla.market_value = price_estimate["estimated_value_avg"]
                        db_sla.market_value_high = price_estimate["estimated_value_high"]
                        db_sla.market_value_low = price_estimate["estimated_value_low"]
                        db_sla.market_confidence = price_estimate["confidence"]
                        
                        # Recalculate fairness with market data
                        from ..models.schemas import SLAData as SLASchema, RedFlag as RedFlagSchema
                        updated_sla = SLASchema(
                            **sla_data.model_dump(),
                            market_value=price_estimate["estimated_value_avg"],
                            market_value_high=price_estimate["estimated_value_high"],
                            market_value_low=price_estimate["estimated_value_low"],
                            market_confidence=price_estimate["confidence"]
                        )
                        current_flags = [RedFlagSchema(**rf) for rf in result.red_flags if isinstance(rf, dict)]
                        
                        new_score, new_explanation = ScoringEngine.calculate_score(
                            sla=updated_sla,
                            contract_type=contract.contract_type
                        )
                        
                        contract.fairness_score = new_score
                        contract.fairness_explanation = new_explanation
                        db_sla.fairness_score = new_score
                        db_sla.fairness_explanation = new_explanation

                vin_lookup_result = {
                    "vin_status": "Valid",
                    "vin_number": extracted_vin,
                    "vehicle_details": vin_data,
                    "cross_check": cross_check,
                    "estimated_value": price_estimate["estimated_value_avg"] if price_estimate else None
                }
                
                # Add mismatch warning
                if cross_check.get("mismatch_detected"):
                    mismatch_clause = ExtractedClause(
                        contract_id=contract.id,
                        section_key="vin_mismatch",
                        section_title="Vehicle Data Mismatch",
                        clause_text=f"VIN: {extracted_vin}",
                        risk_level="medium",
                        risk_reason="Decoded VIN data doesn't match contract details",
                        suggestion="Verify vehicle make, model, and year match the VIN before signing."
                    )
                    db.add(mismatch_clause)
                    
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
            logger.warning(f"VIN/Price analysis non-critical error: {e}")
            vin_lookup_result = {"vin_status": "Lookup Failed", "vin_number": None}
        
        contract.status = "analyzed"
        contract.analyzed_at = datetime.utcnow()
        
        db.commit()
        db.refresh(contract)

        # --- Gap 9: Audit Trail — analysis completed ---
        log_event(
            db=db,
            user_id=current_user.id,
            action=AuditAction.CONTRACT_ANALYZED,
            entity_type="contract",
            entity_id=contract.id,
            details={
                "fairness_score": contract.fairness_score,
                "red_flag_count": len(contract.red_flags or []),
                "contract_type": contract.contract_type
            }
        )
        db.commit()
        
        return _contract_to_response(contract, vin_lookup_result)
        
    except LLMException as e:
        contract.status = "error"
        contract.error_message = str(e)

        # --- Gap 9: Audit Trail — analysis failed ---
        log_event(
            db=db,
            user_id=current_user.id,
            action=AuditAction.LLM_ANALYSIS_FAILED,
            entity_type="contract",
            entity_id=contract.id,
            details={"error": str(e)}
        )
        db.commit()
        
        logger.error(f"LLM analysis failed for contract {contract_id}: {e}")
        raise LLMAnalysisError(detail="AI analysis failed. Please try again later.")


@router.get("/{contract_id}", response_model=ContractResponse)
async def get_contract(
    contract_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """Get a contract by ID with analysis results"""
    contract = db.query(Contract).filter(
        Contract.id == contract_id,
        Contract.user_id == current_user.id
    ).first()
    
    if not contract:
        raise ContractNotFoundError(contract_id=contract_id)
    
    return _contract_to_response(contract)


@router.get("/", response_model=List[ContractResponse])
async def list_contracts(
    skip: int = 0,
    limit: int = 20,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """List all contracts for the current user"""
    contracts = db.query(Contract).filter(
        Contract.user_id == current_user.id
    ).order_by(
        Contract.created_at.desc()
    ).offset(skip).limit(limit).all()
    
    return [_contract_to_response(c) for c in contracts]


@router.delete("/{contract_id}")
async def delete_contract(
    contract_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """Delete a contract and its associated files"""
    contract = db.query(Contract).filter(
        Contract.id == contract_id,
        Contract.user_id == current_user.id
    ).first()
    
    if not contract:
        raise ContractNotFoundError(contract_id=contract_id)
    
    # --- Gap 9: Audit Trail — deletion ---
    filenames = [cf.filename for cf in contract.files]
    log_event(
        db=db,
        user_id=current_user.id,
        action=AuditAction.CONTRACT_DELETED,
        entity_type="contract",
        entity_id=contract_id,
        details={"filenames": filenames}
    )

    # Delete physical files
    for cf in contract.files:
        if cf.file_path and os.path.exists(cf.file_path):
            os.remove(cf.file_path)
    
    db.delete(contract)
    db.commit()
    
    return {"message": "Contract deleted successfully"}


@router.patch("/{contract_id}/status")
async def update_contract_status(
    contract_id: int,
    request: StatusUpdateRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """
    Update contract workflow status (Gap 15).
    
    Allowed transitions: review → analysis → counter_offer → finalized
    """
    contract = db.query(Contract).filter(
        Contract.id == contract_id,
        Contract.user_id == current_user.id
    ).first()
    
    if not contract:
        raise ContractNotFoundError(contract_id=contract_id)
    
    old_status = contract.status
    contract.status = request.status
    
    # Audit trail
    log_event(
        db=db,
        user_id=current_user.id,
        action=AuditAction.CONTRACT_STATUS_CHANGED,
        entity_type="contract",
        entity_id=contract_id,
        details={"old_status": old_status, "new_status": request.status}
    )
    
    db.commit()
    db.refresh(contract)
    
    return {
        "id": contract.id,
        "status": contract.status,
        "message": f"Status updated from '{old_status}' to '{request.status}'"
    }


@router.post("/analyze-text", response_model=QuickAnalysisResponse)
async def analyze_text(
    request: AnalyzeContractRequest
):
    """Quick analysis without saving to database"""
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
        logger.error(f"Quick analysis failed: {e}")
        raise LLMAnalysisError(detail="AI analysis failed. Please try again later.")


@router.post("/compare", response_model=ContractCompareResponse)
async def compare_contracts(
    request: ContractCompareRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """Compare multiple contracts side-by-side"""
    contracts = db.query(Contract).filter(
        Contract.id.in_(request.contract_ids),
        Contract.user_id == current_user.id
    ).all()
    
    if len(contracts) != len(request.contract_ids):
        raise ContractNotFoundError()
    
    for c in contracts:
        if c.status != "analyzed":
            raise ValidationError(
                detail=f"Contract {c.id} has not been analyzed yet."
            )
    
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
    
    # Build SLA data from contract_sla table if available
    sla_data = None
    if contract.sla:
        sla_data = {
            "currency_code": contract.sla.currency_code,
            "apr": contract.sla.apr,
            "term_months": contract.sla.term_months,
            "monthly_payment": contract.sla.monthly_payment,
            "down_payment": contract.sla.down_payment,
            "residual_value": contract.sla.residual_value,
            "mileage_limit": contract.sla.mileage_limit,
            "mileage_overage_fee": contract.sla.mileage_overage_fee,
            "early_termination_fee": contract.sla.early_termination_fee,
            "buyout_price": contract.sla.buyout_price,
            "maintenance_included": contract.sla.maintenance_included,
            "warranty_months": contract.sla.warranty_months,
            "market_value": contract.sla.market_value,
            "market_value_high": contract.sla.market_value_high,
            "market_value_low": contract.sla.market_value_low,
            "market_confidence": contract.sla.market_confidence,
        }
    
    # Build risk assessment from detailed_analysis JSON
    risk_assessment = None
    if contract.detailed_analysis and isinstance(contract.detailed_analysis, dict):
        risk_assessment = contract.detailed_analysis.get("risk_assessment")

    return ContractResponse(
        id=contract.id,
        filename=contract.files[0].filename if contract.files else None,
        contract_type=contract.contract_type,
        status=contract.status,
        raw_text=contract.raw_text[:500] + "..." if contract.raw_text and len(contract.raw_text) > 500 else contract.raw_text,
        sla_data=sla_data,
        detailed_analysis=contract.detailed_analysis,
        risk_assessment=risk_assessment,
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
        
        if c.sla:
            comparison["apr"][key] = c.sla.apr
            comparison["monthly_payment"][key] = c.sla.monthly_payment
            comparison["term_months"][key] = c.sla.term_months
            comparison["mileage_limit"][key] = c.sla.mileage_limit
        else:
            comparison["apr"][key] = None
            comparison["monthly_payment"][key] = None
            comparison["term_months"][key] = None
            comparison["mileage_limit"][key] = None
        
        comparison["fairness_score"][key] = c.fairness_score
        comparison["red_flag_count"][key] = len(c.red_flags or [])
    
    return comparison


def _generate_recommendation(contracts: List[Contract]) -> str:
    """Generate a recommendation based on comparison"""
    best = max(contracts, key=lambda c: c.fairness_score or 0)
    
    if not best.fairness_score:
        return "Unable to determine best contract. Please review the details manually."
    
    if best.fairness_score >= 80:
        return f"Contract {best.id} appears to be the best option with a fairness score of {best.fairness_score}/100."
    elif best.fairness_score >= 60:
        return f"Contract {best.id} has the highest fairness score ({best.fairness_score}/100), but consider negotiating the red flags."
    else:
        return "All contracts have concerning fairness scores. Consider negotiating better terms or exploring other options."
