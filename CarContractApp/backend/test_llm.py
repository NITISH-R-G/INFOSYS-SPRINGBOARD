
import asyncio
from app.services.llm_service import llm_service

async def test_llm():
    print("Testing LLM Service with gemini-2.0-flash...")
    try:
        result = await llm_service.analyze_contract("This is a test contract for a car lease. Monthly payment is $500.", "lease")
        print("\nSUCCESS! Analysis Result:")
        print(f"Fairness Score: {result.fairness_score}")
        print(f"Summary: {result.sla_data}")
    except Exception as e:
        print(f"\nFAILED: {e}")

if __name__ == "__main__":
    asyncio.run(test_llm())
