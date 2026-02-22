import asyncio
from app.services.llm_service import llm_service

async def main():
    text = "This is a mock contract. The seller agrees to sell the car to the buyer for $10,000. " * 10
    try:
        result = await llm_service.analyze_contract(text, "lease")
        print("Success:", result)
    except Exception as e:
        print("ERROR:", type(e).__name__)
        print(e)
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    asyncio.run(main())
