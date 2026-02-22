"""
Background Tasks for Document Processing
Celery tasks that handle OCR extraction, LLM analysis, and data persistence.
"""
import os
import logging
import time
from datetime import datetime

from .celery_app import celery_app
from .config import settings
from .database import SessionLocal, Contract, ContractFile, ContractPage, ContractSLA, ExtractedClause

logger = logging.getLogger(__name__)


def _get_db():
    """Get a database session for use in background tasks."""
    db = SessionLocal()
    try:
        return db
    except Exception:
        db.close()
        raise


@celery_app.task(bind=True, name="process_contract", max_retries=2, default_retry_delay=30)
def process_contract_task(self, contract_id: int, file_path: str):
    """
    Background task to process a contract document:
    1. OCR text extraction (with per-page confidence)
    2. LLM-powered SLA extraction
    3. Save results to normalized tables

    Updates task state with progressive messages for frontend display.
    """
    db = _get_db()

    try:
        contract = db.query(Contract).filter(Contract.id == contract_id).first()
        if not contract:
            logger.error(f"Contract {contract_id} not found in DB.")
            return {"status": "error", "message": "Contract not found"}

        # --- Stage 1: Scanning Document ---
        self.update_state(state="SCANNING", meta={
            "stage": "scanning",
            "message": "Scanning document...",
            "progress": 10
        })

        contract.status = "scanning"
        db.commit()

        # Read file bytes
        if not os.path.exists(file_path):
            raise FileNotFoundError(f"File not found: {file_path}")

        with open(file_path, "rb") as f:
            file_bytes = f.read()

        # Perform OCR
        from .services.ocr_service import ocr_service
        start_time = time.time()
        raw_text, file_type = ocr_service.extract_text(file_bytes, os.path.basename(file_path))
        ocr_time_ms = int((time.time() - start_time) * 1000)

        # Save raw text and create page records
        contract.raw_text = raw_text

        contract_file = db.query(ContractFile).filter(
            ContractFile.contract_id == contract_id
        ).first()

        if contract_file:
            # Create a single page record (can be expanded for multi-page later)
            page = ContractPage(
                contract_file_id=contract_file.id,
                page_number=1,
                raw_text=raw_text,
                ocr_confidence=85.0,  # Default confidence; enhanced OCR provides real values
                processing_time_ms=ocr_time_ms
            )
            db.add(page)

        db.commit()

        # --- Stage 2: Extracting Terms ---
        self.update_state(state="EXTRACTING", meta={
            "stage": "extracting",
            "message": "Extracting APR, payments, and terms...",
            "progress": 40
        })

        contract.status = "extracting"
        db.commit()

        # LLM Analysis (synchronous wrapper since Celery tasks are sync)
        import asyncio
        from .services.llm_service import llm_service, LLMException

        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)
        try:
            result = loop.run_until_complete(
                llm_service.analyze_contract(raw_text, contract.contract_type)
            )
        finally:
            loop.close()

        # --- Stage 3: Calculating Fairness Score ---
        self.update_state(state="ANALYZING", meta={
            "stage": "analyzing",
            "message": "Calculating Fairness Score...",
            "progress": 70
        })

        contract.status = "analyzing"
        db.commit()

        # Save SLA data
        sla_data = result.sla_data
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
            fairness_score=result.fairness_score,
            fairness_explanation=result.fairness_explanation,
        )
        db.add(db_sla)

        # Save red flags to extracted_clauses
        processed_red_flags = []
        for flag in result.red_flags:
            flag_dict = flag.model_dump() if hasattr(flag, 'model_dump') else flag

            db_clause = ExtractedClause(
                contract_id=contract.id,
                section_key=flag_dict.get("title", "unknown").lower().replace(" ", "_"),
                section_title=flag_dict.get("title", "Unknown"),
                clause_text=flag_dict.get("clause_text", ""),
                risk_level=flag_dict.get("risk_level", "medium"),
                risk_reason=flag_dict.get("why_flag", ""),
                suggestion=flag_dict.get("suggestion", ""),
            )
            db.add(db_clause)
            processed_red_flags.append(flag_dict)

        # Update contract
        contract.fairness_score = result.fairness_score
        contract.fairness_explanation = result.fairness_explanation
        contract.confidence_score = result.confidence_score
        contract.contract_type = result.contract_type
        contract.red_flags = processed_red_flags
        contract.status = "analyzed"
        contract.analyzed_at = datetime.utcnow()

        if result.detailed_analysis:
            contract.detailed_analysis = result.detailed_analysis.model_dump()

        db.commit()

        # --- Stage 4: Complete ---
        self.update_state(state="SUCCESS", meta={
            "stage": "complete",
            "message": "Analysis complete!",
            "progress": 100,
            "contract_id": contract_id,
            "fairness_score": result.fairness_score
        })

        logger.info(f"Contract {contract_id} processed successfully. Score: {result.fairness_score}")

        return {
            "status": "success",
            "contract_id": contract_id,
            "fairness_score": result.fairness_score,
            "message": "Analysis complete!"
        }

    except Exception as e:
        logger.error(f"Task failed for contract {contract_id}: {e}", exc_info=True)

        # Update contract status
        try:
            contract = db.query(Contract).filter(Contract.id == contract_id).first()
            if contract:
                contract.status = "error"
                contract.error_message = str(e)[:500]
                db.commit()
        except Exception:
            pass

        self.update_state(state="FAILURE", meta={
            "stage": "error",
            "message": "Processing failed. Please try again.",
            "progress": 0
        })

        raise self.retry(exc=e) if self.request.retries < self.max_retries else None

    finally:
        db.close()
