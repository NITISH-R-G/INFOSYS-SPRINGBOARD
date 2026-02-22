import pytest
import asyncio
from unittest.mock import patch

from app.services.pricing_adapters import EdmundsAdapter, TrueCarAdapter
from app.services.price_service import price_service

@pytest.mark.asyncio
async def test_edmunds_adapter_success():
    adapter = EdmundsAdapter()
    
    # Patch random to ensure the fallback/exception isn't hit
    with patch('random.random', return_value=0.5):
        with patch('asyncio.sleep', return_value=None):
            result = await adapter.fetch_price_data("Honda", "Civic", 2022)
            
            assert "source" in result
            assert result["source"] == "Edmunds"
            assert "msrp" in result
            assert "estimated_market_value" in result

@pytest.mark.asyncio
async def test_edmunds_adapter_failure():
    adapter = EdmundsAdapter()
    
    # Patch random to trigger the 10% rate limit failure
    with patch('random.random', return_value=0.05):
        with patch('asyncio.sleep', return_value=None):
            with pytest.raises(Exception) as exc_info:
                await adapter.fetch_price_data("Honda", "Civic", 2022)
            assert "Edmunds API timeout or rate limit exceeded" in str(exc_info.value)

@pytest.mark.asyncio
async def test_price_service_graceful_degradation():
    """
    Test that the PriceService still returns a recommendation even if
    one or more adapters fail.
    """
    # Cause Edmunds to fail to ensure graceful degradation doesn't crash the whole run.
    with patch('random.random', return_value=0.0):
        with patch('asyncio.sleep', return_value=None):
            # This will result in TrueCar and Edmunds throwing Exceptions
            rec = await price_service.generate_recommendation("Toyota", "Camry", 2021)
            
            # Should still return valid algorithmic bounds
            assert rec["fair_price_low"] > 0
            assert rec["fair_price_high"] > 0
            assert "Edmunds" not in rec["data_sources"]
            assert "TrueCar" not in rec["data_sources"]

@pytest.mark.asyncio
async def test_price_service_successful_aggregation():
    """
    Test that the PriceService aggregates data correctly if adapters succeed.
    """
    with patch('random.random', return_value=0.9):
        with patch('asyncio.sleep', return_value=None):
            rec = await price_service.generate_recommendation("Tesla", "Model 3", 2023)
            
            assert "Edmunds" in rec["data_sources"]
            assert "TrueCar" in rec["data_sources"]
            assert "AutoTrader" in rec["data_sources"]
            assert rec["fair_price_low"] < rec["fair_price_high"]
            assert rec["confidence"] == "high"
