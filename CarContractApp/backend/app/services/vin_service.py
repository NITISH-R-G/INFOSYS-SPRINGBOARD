"""
VIN Lookup Service
Fetches vehicle information from NHTSA API
"""
import re
import httpx
import asyncio
import random
from datetime import datetime
from typing import Optional, Dict, Any, List
from ..config import settings


class VINService:
    """Service for VIN lookup and vehicle data"""
    
    # VIN character weights for checksum calculation
    VIN_WEIGHTS = [8, 7, 6, 5, 4, 3, 2, 10, 0, 9, 8, 7, 6, 5, 4, 3, 2]
    VIN_TRANSLITERATION = {
        'A': 1, 'B': 2, 'C': 3, 'D': 4, 'E': 5, 'F': 6, 'G': 7, 'H': 8,
        'J': 1, 'K': 2, 'L': 3, 'M': 4, 'N': 5, 'P': 7, 'R': 9,
        'S': 2, 'T': 3, 'U': 4, 'V': 5, 'W': 6, 'X': 7, 'Y': 8, 'Z': 9
    }
    
    # Keywords that often appear near VIN
    VIN_CONTEXT_KEYWORDS = [
        'vin', 'vehicle identification number', 'chassis number',
        'vehicle serial', 'registration', 'car details', 'manufacturer'
    ]
    
    def __init__(self):
        self.base_url = settings.NHTSA_API_BASE
        self.timeout = 30.0
    
    def extract_vin_from_text(self, text: str) -> Optional[str]:
        """
        Extract VIN from document text using regex and validation.
        
        Args:
            text: OCR extracted text from contract
            
        Returns:
            Valid VIN string or None
        """
        if not text:
            return None
        
        text_upper = text.upper()
        
        # Pattern: 17 alphanumeric chars excluding I, O, Q
        vin_pattern = r'\b[A-HJ-NPR-Z0-9]{17}\b'
        
        # Find all potential VINs
        candidates = re.findall(vin_pattern, text_upper)
        
        if not candidates:
            return None
        
        # Score candidates by context and validation
        scored_candidates = []
        for vin in candidates:
            score = 0
            
            # Check if VIN appears near context keywords
            vin_index = text_upper.find(vin)
            if vin_index != -1:
                context_window = text_upper[max(0, vin_index-100):vin_index+120].lower()
                for keyword in self.VIN_CONTEXT_KEYWORDS:
                    if keyword in context_window:
                        score += 10
            
            # Validate format
            if self._validate_vin(vin):
                score += 20
            
            # Validate checksum (most reliable)
            if self._validate_checksum(vin):
                score += 50
            
            scored_candidates.append((vin, score))
        
        # Sort by score descending
        scored_candidates.sort(key=lambda x: x[1], reverse=True)
        
        # Return highest scoring VIN if it passes basic validation
        if scored_candidates and scored_candidates[0][1] >= 20:
            return scored_candidates[0][0]
        
        return None
    
    def _validate_checksum(self, vin: str) -> bool:
        """
        Validate VIN using North American checksum (position 9).
        Works for vehicles sold in US/Canada.
        """
        if len(vin) != 17:
            return False
        
        try:
            total = 0
            for i, char in enumerate(vin.upper()):
                if char.isdigit():
                    value = int(char)
                else:
                    value = self.VIN_TRANSLITERATION.get(char)
                    if value is None:
                        return False
                
                total += value * self.VIN_WEIGHTS[i]
            
            remainder = total % 11
            check_digit = vin[8]
            
            if remainder == 10:
                return check_digit == 'X'
            else:
                return check_digit == str(remainder)
        except Exception:
            return False
    
    def cross_check_with_contract(
        self, 
        vin_data: Dict[str, Any], 
        contract_text: str
    ) -> Dict[str, Any]:
        """
        Cross-check decoded VIN data with contract content.
        
        Returns:
            Dict with mismatch_detected flag and details
        """
        result = {
            "mismatch_detected": False,
            "mismatch_details": [],
            "confidence_score": 100
        }
        
        if not vin_data or not contract_text:
            return result
        
        text_lower = contract_text.lower()
        
        # Check make
        make = vin_data.get("make")
        if make and make.lower() not in text_lower:
            # Maybe mentioned differently, reduce confidence
            result["confidence_score"] -= 10
        
        # Check model
        model = vin_data.get("model")
        if model and model.lower() not in text_lower:
            result["confidence_score"] -= 10
        
        # Check year
        year = vin_data.get("year")
        if year and str(year) not in contract_text:
            result["mismatch_detected"] = True
            result["mismatch_details"].append(
                f"VIN decoded year ({year}) not found in contract"
            )
            result["confidence_score"] -= 20
        
        return result

    def _validate_vin(self, vin: str) -> bool:
        """Validate VIN format"""
        if not vin:
            return False
        
        # VIN should be 17 characters
        if len(vin) != 17:
            return False
        
        # VIN should be alphanumeric (excluding I, O, Q)
        valid_chars = "ABCDEFGHJKLMNPRSTUVWXYZ0123456789"
        return all(c.upper() in valid_chars for c in vin)

    async def decode_vin(self, vin: str) -> Dict[str, Any]:
        """
        Decode a VIN and get vehicle information
        
        Args:
            vin: 17-character Vehicle Identification Number
            
        Returns:
            Dict with vehicle information
        """
        if not self._validate_vin(vin):
            raise VINException(f"Invalid VIN format: {vin}")
        
        async with httpx.AsyncClient(timeout=self.timeout) as client:
            try:
                url = f"{self.base_url}/DecodeVin/{vin}?format=json"
                response = await client.get(url)
                response.raise_for_status()
                
                data = response.json()
                return self._parse_decode_response(data, vin)
                
            except httpx.HTTPError as e:
                raise VINException(f"NHTSA API request failed: {str(e)}")
    
    async def get_recalls(self, make: str, model: str, year: int) -> List[Dict[str, Any]]:
        """
        Get recall information for a vehicle
        """
        async with httpx.AsyncClient(timeout=self.timeout) as client:
            try:
                url = f"https://api.nhtsa.gov/recalls/recallsByVehicle?make={make}&model={model}&modelYear={year}"
                response = await client.get(url)
                response.raise_for_status()
                
                data = response.json()
                return self._parse_recalls_response(data)
                
            except httpx.HTTPError as e:
                return []
                
    async def _mock_edmunds_api(self, make: str, model: str, year: int) -> Dict[str, Any]:
        """Simulate a call to Edmunds API for MSRP and incentives"""
        await asyncio.sleep(random.uniform(0.5, 1.2))  # simulate network delay
        
        # Base pricing logic based on year
        base_msrp = 25000 + (year - 2010) * 1500
        if make and make.lower() in ["bmw", "mercedes-benz", "audi", "lexus", "porsche"]:
            base_msrp += 15000
        
        # Simulate occasional failure
        if random.random() < 0.05:
            raise VINException("Edmunds API timeout")
            
        return {
            "msrp": float(base_msrp),
            "incentives": ["$500 Cash Bonus", "1.9% APR for 36 Months"] if year >= 2023 else [],
        }

    async def _mock_truecar_api(self, make: str, model: str, year: int) -> Dict[str, Any]:
        """Simulate a call to TrueCar API for market averages"""
        await asyncio.sleep(random.uniform(0.6, 1.5))  # simulate network delay
        
        base_market = 24000 + (year - 2010) * 1400
        if make and make.lower() in ["bmw", "mercedes-benz", "audi", "lexus", "porsche"]:
            base_market += 14500
            
        # Add some random variance
        variance = base_market * random.uniform(-0.05, 0.05)
        market_average = base_market + variance
        
        # Simulate occasional failure
        if random.random() < 0.05:
            raise VINException("TrueCar API unavailable")
            
        return {
            "market_average": round(market_average, 2),
            "fair_price_low": round(market_average * 0.95, 2),
            "fair_price_high": round(market_average * 1.05, 2),
        }
    
    async def get_full_vehicle_info(self, vin: str) -> Dict[str, Any]:
        """
        Get complete vehicle information including recalls, pricing, and market data
        """
        # 1. Base API Call (NHTSA)
        vehicle_info = await self.decode_vin(vin)
        
        make = vehicle_info.get("make")
        model = vehicle_info.get("model")
        year = vehicle_info.get("year")
        
        # Prepare concurrent API calls
        tasks = []
        
        # Add recalls task
        if make and model and year:
            tasks.append(self.get_recalls(make, model, year))
        else:
            tasks.append(self._mock_empty_future([]))
            
        # Add Pricing/Market tasks
        if make and model and year:
            tasks.append(self._mock_edmunds_api(make, model, year))
            tasks.append(self._mock_truecar_api(make, model, year))
        else:
            tasks.append(self._mock_empty_future({}))
            tasks.append(self._mock_empty_future({}))
            
        # Execute secondary calls concurrently, catching exceptions to prevent failure
        results = await asyncio.gather(*tasks, return_exceptions=True)
        
        # 2. Extract results & populate normalization layer
        recalls_result = results[0]
        edmunds_result = results[1]
        truecar_result = results[2]
        
        # Process Recalls
        if isinstance(recalls_result, Exception):
            vehicle_info["recalls"] = []
            vehicle_info["recall_count"] = 0
        else:
            vehicle_info["recalls"] = recalls_result
            vehicle_info["recall_count"] = len(recalls_result) if recalls_result else 0
            
        data_sources = ["NHTSA"]
        confidence_indicators = {"nhtsa": 100}
            
        # Process Edmunds Data
        if isinstance(edmunds_result, Exception):
            vehicle_info["msrp"] = None
            vehicle_info["incentives"] = []
            confidence_indicators["edmunds"] = 0
        else:
            vehicle_info.update(edmunds_result)
            data_sources.append("Edmunds")
            confidence_indicators["edmunds"] = 90
            
        # Process TrueCar Data
        if isinstance(truecar_result, Exception):
            vehicle_info["market_average"] = None
            vehicle_info["fair_price_low"] = None
            vehicle_info["fair_price_high"] = None
            confidence_indicators["truecar"] = 0
        else:
            vehicle_info.update(truecar_result)
            data_sources.append("TrueCar")
            confidence_indicators["truecar"] = 85
            
        # Normalize and add metadata layer
        vehicle_info["data_sources"] = data_sources
        vehicle_info["timestamp"] = datetime.utcnow().isoformat()
        vehicle_info["confidence_indicators"] = confidence_indicators
        
        return vehicle_info
        
    async def _mock_empty_future(self, default_val: Any) -> Any:
        return default_val

    def _parse_decode_response(self, data: dict, vin: str) -> Dict[str, Any]:
        """Parse NHTSA decode response into clean format"""
        results = data.get("Results", [])
        
        # Create a lookup dict from results
        lookup = {}
        for item in results:
            var_name = item.get("Variable", "")
            value = item.get("Value")
            if value and value.strip():
                lookup[var_name] = value.strip()
        
        return {
            "vin": vin,
            "make": lookup.get("Make"),
            "model": lookup.get("Model"),
            "year": self._safe_int(lookup.get("Model Year")),
            "trim": lookup.get("Trim"),
            "body_type": lookup.get("Body Class"),
            "engine": self._build_engine_string(lookup),
            "transmission": lookup.get("Transmission Style"),
            "drivetrain": lookup.get("Drive Type"),
            "fuel_type": lookup.get("Fuel Type - Primary"),
            "doors": self._safe_int(lookup.get("Doors")),
            "vehicle_type": lookup.get("Vehicle Type"),
            "plant_city": lookup.get("Plant City"),
            "plant_country": lookup.get("Plant Country"),
            "gvwr": lookup.get("Gross Vehicle Weight Rating From"),
            "source": "NHTSA"
        }
    
    def _build_engine_string(self, lookup: dict) -> Optional[str]:
        """Build descriptive engine string from components"""
        parts = []
        
        displacement = lookup.get("Displacement (L)")
        if displacement:
            parts.append(f"{displacement}L")
        
        cylinders = lookup.get("Engine Number of Cylinders")
        if cylinders:
            parts.append(f"{cylinders}-cyl")
        
        config = lookup.get("Engine Configuration")
        if config:
            parts.append(config)
        
        hp = lookup.get("Engine Brake (hp) From")
        if hp:
            parts.append(f"{hp}hp")
        
        return " ".join(parts) if parts else None
    
    def _parse_recalls_response(self, data: dict) -> List[Dict[str, Any]]:
        """Parse recalls API response"""
        results = data.get("results", [])
        
        recalls = []
        for item in results:
            recalls.append({
                "campaign_number": item.get("NHTSACampaignNumber"),
                "report_date": item.get("ReportReceivedDate"),
                "component": item.get("Component"),
                "summary": item.get("Summary"),
                "consequence": item.get("Consequence"),
                "remedy": item.get("Remedy"),
                "manufacturer": item.get("Manufacturer")
            })
        
        return recalls
    
    def _safe_int(self, value: Any) -> Optional[int]:
        """Safely convert value to int"""
        if value is None:
            return None
        try:
            return int(value)
        except (ValueError, TypeError):
            return None


class VINException(Exception):
    """Custom exception for VIN lookup errors"""
    pass


# Singleton instance
vin_service = VINService()
