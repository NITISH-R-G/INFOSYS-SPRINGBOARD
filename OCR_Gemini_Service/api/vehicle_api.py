import httpx
import asyncio
import random
from typing import Dict, Any, Optional

class VehicleAPIClient:
    """
    Handles interactions with vehicle valuation APIs.
    Includes a real integration for NHTSA vPIC to decode VINs,
    and mock integrations for Edmunds and TrueCar to simulate market pricing.
    """
    
    NHTSA_URL = "https://vpic.nhtsa.dot.gov/api/vehicles/DecodeVin/{vin}?format=json"

    def __init__(self):
        # We will share an httpx async client for real requests
        self.client = httpx.AsyncClient(timeout=10.0)

    async def close(self):
        await self.client.aclose()

    async def decode_vin(self, vin: str) -> Dict[str, Any]:
        """
        Calls the real NHTSA vPIC API to decode the given VIN.
        """
        try:
            response = await self.client.get(self.NHTSA_URL.format(vin=vin))
            response.raise_for_status()
            data = response.json()
            
            # Extract basic info
            results = data.get("Results", [])
            decoded_data = {
                "vin": vin,
                "make": "Unknown",
                "model": "Unknown",
                "year": "Unknown",
                "trim": "Unknown",
                "body_class": "Unknown",
                "engine_cylinders": "Unknown",
            }
            
            for item in results:
                variable = item.get("Variable")
                value = item.get("Value")
                if value is None or str(value).strip() == "":
                    continue
                
                if variable == "Make":
                    decoded_data["make"] = value
                elif variable == "Model":
                    decoded_data["model"] = value
                elif variable == "Model Year":
                    decoded_data["year"] = value
                elif variable == "Trim":
                    decoded_data["trim"] = value
                elif variable == "Body Class":
                    decoded_data["body_class"] = value
                elif variable == "Engine Number of Cylinders":
                    decoded_data["engine_cylinders"] = value

            return decoded_data
        except Exception as e:
            # Return baseline failure dictionary
            return {"vin": vin, "error": f"NHTSA decoding failed: {str(e)}"}

    async def _mock_edmunds_api(self, vehicle_data: Dict[str, Any]) -> Dict[str, Any]:
        """
        Simulates querying the Edmunds API for TMV.
        """
        await asyncio.sleep(0.5) # Simulate network latency
        
        # We generate deterministic "random" prices based on the VIN length/hash to ensure stable responses
        vin = vehicle_data.get("vin", "")
        base_price = 25000 + (hash(vin) % 15000) if vin else 30000
        
        # Edmunds pricing simulation
        msrp = base_price * 1.05
        invoice = base_price * 0.95
        tmv = base_price * 0.98  # True Market Value
        
        return {
            "source": "Edmunds TMV",
            "metrics": {
                "msrp": round(msrp, 2),
                "invoice_price": round(invoice, 2),
                "market_average": round(tmv, 2),
                "fair_range_low": round(tmv * 0.97, 2),
                "fair_range_high": round(tmv * 1.03, 2),
            },
            "confidence_score": 85
        }

    async def _mock_truecar_api(self, vehicle_data: Dict[str, Any]) -> Dict[str, Any]:
        """
        Simulates querying the TrueCar API.
        """
        await asyncio.sleep(0.6) # Simulate network latency
        
        vin = vehicle_data.get("vin", "")
        # Slightly different logical base price
        base_price = 24500 + (hash(vin) % 16000) if vin else 29000
        
        market_average = base_price
        
        return {
            "source": "TrueCar",
            "metrics": {
                "market_average": round(market_average, 2),
                "fair_range_low": round(market_average * 0.95, 2),
                "fair_range_high": round(market_average * 1.05, 2),
            },
            "confidence_score": 80
        }

    async def get_valuation(self, vin: str) -> Dict[str, Any]:
        """
        Orchestrates the workflow:
        1. Decodes VIN
        2. Queries Edmunds and TrueCar concurrently
        3. Aggregates and normalizes the results.
        """
        decoded_vehicle = await self.decode_vin(vin)
        
        # Even if decoding partially fails, we attempt to get mock valuations
        edmunds_task = asyncio.create_task(self._mock_edmunds_api(decoded_vehicle))
        truecar_task = asyncio.create_task(self._mock_truecar_api(decoded_vehicle))
        
        edmunds_res, truecar_res = await asyncio.gather(edmunds_task, truecar_task)
        
        # Normalizing & Aggregating the responses.
        # Use a simple average between the two mock sources.
        e_metrics = edmunds_res["metrics"]
        t_metrics = truecar_res["metrics"]
        
        avg_market = (e_metrics["market_average"] + t_metrics["market_average"]) / 2
        avg_low = (e_metrics["fair_range_low"] + t_metrics["fair_range_low"]) / 2
        avg_high = (e_metrics["fair_range_high"] + t_metrics["fair_range_high"]) / 2
        
        # Use Edmunds for msrp as Truecar mock didn't provide it
        msrp = e_metrics.get("msrp", avg_market * 1.05)
        
        normalized_response = {
            "vehicle_identifiers": decoded_vehicle,
            "pricing_metrics": {
                "msrp": round(msrp, 2),
                "market_average": round(avg_market, 2),
                "fair_range_low": round(avg_low, 2),
                "fair_range_high": round(avg_high, 2),
            },
            "metadata": {
                "sources_used": ["NHTSA", "Edmunds (Mock)", "TrueCar (Mock)"],
                "aggregated_confidence_score": (edmunds_res["confidence_score"] + truecar_res["confidence_score"]) / 2,
                "timestamp": "now" # In reality, use datetime
            }
        }
        
        return normalized_response
