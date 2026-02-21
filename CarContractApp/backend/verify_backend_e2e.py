import os
import sys
import asyncio
import json
import fitz  # PyMuPDF

# Add app to path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from app.services.ocr_service import ocr_service
from app.services.llm_service import llm_service
from app.config import settings

async def main():
    print("--- Starting Backend E2E Verification ---")
    
    # 1. Create a dummy PDF
    print("\n[INFO] Creating dummy PDF contract...")
    doc = fitz.open()
    page = doc.new_page()
    text = """
    VEHICLE LEASE AGREEMENT
    
    Lessor: AutoFinance Corp
    Lessee: John Doe
    Date: 2024-01-15
    
    1. Vehicle Description:
       Make: Toyota
       Model: Camry
       Year: 2024
       VIN: 4T1B11HK4RU123456
       
    2. Lease Terms:
       Monthly Payment: $450.00
       Term: 36 months
       Down Payment: $2,000.00
       
    3. Mileage:
       Allowed Mileage: 12,000 miles per year
       Excess Charge: $0.25 per mile
       
    4. Early Termination:
       Early termination is allowed with a fee of 3 monthly payments.
       
    5. Purchase Option:
       Purchase Option Price: $18,500.00
    """
    page.insert_text((50, 50), text)
    pdf_bytes = doc.tobytes()
    doc.close()
    print("[SUCCESS] Dummy PDF created.")
    
    # 2. Test OCR Service (Digital PDF path)
    print("\n[INFO] Testing OCR Service (Digital PDF)...")
    try:
        extracted_text, file_type = ocr_service.extract_text(pdf_bytes, "test_contract.pdf")
        print(f"[SUCCESS] Text extracted ({len(extracted_text)} chars).")
        print(f"Snippet: {extracted_text[:100]}...")
    except Exception as e:
        print(f"[FAIL] OCR Extraction failed: {e}")
        return

    # 3. Test LLM Service
    print("\n[INFO] Testing LLM Service (Contract Analysis)...")
    if not settings.GEMINI_API_KEY:
        print("[FAIL] GEMINI_API_KEY not set.")
        return
        
    try:
        # We need to run async method
        analysis_result = await llm_service.analyze_contract(extracted_text)
        
        print(f"[SUCCESS] LLM Analysis completed.")
        print(f"Confidence Score: {analysis_result.confidence_score}")
        print(f"Fairness Score: {analysis_result.fairness_score}")
        
        # Check specific fields
        sla = analysis_result.sla_data
        print(f"Monthly Payment: {sla.monthly_payment}")
        print(f"Mileage Limit: {sla.mileage_limit}")
        
        if sla.monthly_payment == 450.0 and sla.mileage_limit == 12000:
            print("[SUCCESS] Data extraction matches expected values.")
        else:
            print("[WARN] Data extraction mismatch.")
            
    except Exception as e:
        print(f"[FAIL] LLM Analysis failed: {e}")

if __name__ == "__main__":
    asyncio.run(main())
