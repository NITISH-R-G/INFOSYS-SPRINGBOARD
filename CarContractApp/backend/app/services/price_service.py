"""
Price Estimation Service
Estimates vehicle fair market value using available data sources
"""
import httpx
import asyncio
from typing import Optional, Dict, Any, List
from ..config import settings
from .pricing_adapters import (
    EdmundsAdapter, TrueCarAdapter, AutoTraderAdapter, OpenDataSoftAdapter
)


class PriceService:
    """Service for vehicle price estimation"""
    
    # Average depreciation rates by year
    DEPRECIATION_RATES = {
        0: 1.00,   # New
        1: 0.80,   # 1 year - 20% depreciation
        2: 0.70,   # 2 years
        3: 0.62,   # 3 years
        4: 0.55,   # 4 years
        5: 0.49,   # 5 years
        6: 0.44,
        7: 0.40,
        8: 0.36,
        9: 0.33,
        10: 0.30,
    }
    
    # Base MSRP estimates by segment (rough averages)
    SEGMENT_BASE_MSRP = {
        "economy": 22000,
        "compact": 26000,
        "midsize": 30000,
        "fullsize": 38000,
        "luxury": 55000,
        "suv_compact": 32000,
        "suv_midsize": 42000,
        "suv_fullsize": 55000,
        "truck": 45000,
        "sports": 50000,
    }
    
    # Premium brands multiplier
    PREMIUM_BRANDS = {
        "BMW": 1.4,
        "Mercedes-Benz": 1.5,
        "Audi": 1.35,
        "Lexus": 1.3,
        "Porsche": 1.8,
        "Land Rover": 1.5,
        "Jaguar": 1.4,
        "Cadillac": 1.25,
        "Lincoln": 1.2,
        "Infiniti": 1.2,
        "Acura": 1.15,
        "Volvo": 1.25,
        "Tesla": 1.4,
    }
    
    def __init__(self):
        self.current_year = 2026  # Current year
        self.edmunds = EdmundsAdapter()
        self.truecar = TrueCarAdapter()
        self.autotrader = AutoTraderAdapter()
        self.opendata_soft = OpenDataSoftAdapter()
    
    async def estimate_price(
        self,
        make: str,
        model: str,
        year: int,
        mileage: Optional[int] = None,
        trim: Optional[str] = None,
        condition: str = "good"
    ) -> Dict[str, Any]:
        """
        Estimate vehicle price based on make, model, year, and condition
        
        Args:
            make: Vehicle make (e.g., "Toyota")
            model: Vehicle model (e.g., "Camry")
            year: Model year
            mileage: Current mileage (optional)
            trim: Trim level (optional)
            condition: Vehicle condition (excellent, good, fair, poor)
            
        Returns:
            Price estimation dict with range
        """
        # Calculate vehicle age
        age = max(0, self.current_year - year)
        
        # Get base value
        base_value = self._get_base_value(make, model, trim)
        
        # Apply depreciation
        depreciation_rate = self._get_depreciation_rate(age)
        depreciated_value = base_value * depreciation_rate
        
        # Apply brand premium/discount
        brand_multiplier = self.PREMIUM_BRANDS.get(make, 1.0)
        adjusted_value = depreciated_value * brand_multiplier
        
        # Apply mileage adjustment
        if mileage is not None:
            mileage_adj = self._calculate_mileage_adjustment(mileage, age)
            adjusted_value *= mileage_adj
        
        # Apply condition adjustment
        condition_multiplier = self._get_condition_multiplier(condition)
        final_value = adjusted_value * condition_multiplier
        
        # Calculate range (±10%)
        low = round(final_value * 0.90, -2)  # Round to nearest 100
        high = round(final_value * 1.10, -2)
        avg = round(final_value, -2)
        
        # Determine confidence
        confidence = self._calculate_confidence(make, model, year, mileage)
        
        return {
            "make": make,
            "model": model,
            "year": year,
            "mileage": mileage,
            "condition": condition,
            "estimated_value_low": max(low, 1000),
            "estimated_value_high": max(high, 2000),
            "estimated_value_avg": max(avg, 1500),
            "confidence": confidence,
            "source": "algorithmic_estimate",
            "notes": self._generate_notes(make, model, year, age, condition)
        }
    
    def _get_base_value(self, make: str, model: str, trim: Optional[str] = None) -> float:
        """Determine base MSRP based on segment detection"""
        
        # Simple segment detection based on model name patterns
        model_lower = model.lower() if model else ""
        
        # SUV detection
        suv_keywords = ["suv", "crossover", "cx-", "rav4", "cr-v", "pilot", "highlander", 
                       "explorer", "tahoe", "suburban", "x3", "x5", "q5", "q7", "gx", "rx"]
        if any(kw in model_lower for kw in suv_keywords):
            if "compact" in model_lower or len(model) <= 4:
                return self.SEGMENT_BASE_MSRP["suv_compact"]
            return self.SEGMENT_BASE_MSRP["suv_midsize"]
        
        # Truck detection
        truck_keywords = ["f-150", "silverado", "ram", "tundra", "tacoma", "frontier", "ranger", "colorado"]
        if any(kw in model_lower for kw in truck_keywords):
            return self.SEGMENT_BASE_MSRP["truck"]
        
        # Sports car detection
        sports_keywords = ["mustang", "camaro", "challenger", "corvette", "86", "brz", "miata", "z", "gt"]
        if any(kw in model_lower for kw in sports_keywords):
            return self.SEGMENT_BASE_MSRP["sports"]
        
        # Check if luxury brand
        if make in self.PREMIUM_BRANDS:
            return self.SEGMENT_BASE_MSRP["luxury"]
        
        # Default based on common models
        economy_models = ["civic", "corolla", "sentra", "elantra", "forte", "mazda3"]
        if any(m in model_lower for m in economy_models):
            return self.SEGMENT_BASE_MSRP["compact"]
        
        midsize_models = ["accord", "camry", "altima", "sonata", "k5", "mazda6"]
        if any(m in model_lower for m in midsize_models):
            return self.SEGMENT_BASE_MSRP["midsize"]
        
        # Default to compact
        return self.SEGMENT_BASE_MSRP["compact"]
    
    def _get_depreciation_rate(self, age: int) -> float:
        """Get depreciation rate based on vehicle age"""
        if age in self.DEPRECIATION_RATES:
            return self.DEPRECIATION_RATES[age]
        elif age > 10:
            # Beyond 10 years, depreciate slower
            return max(0.15, 0.30 - (age - 10) * 0.015)
        return 0.30
    
    def _calculate_mileage_adjustment(self, mileage: int, age: int) -> float:
        """
        Calculate price adjustment based on mileage
        Average mileage is ~12,000/year
        """
        expected_mileage = age * 12000
        
        if mileage <= 0:
            return 1.0
        
        # Calculate difference from expected
        diff = mileage - expected_mileage
        diff_percent = diff / max(expected_mileage, 12000)
        
        # Adjust price: -10% for 50% over expected, +5% for 50% under
        if diff > 0:
            return max(0.75, 1 - (diff_percent * 0.2))
        else:
            return min(1.10, 1 - (diff_percent * 0.1))
    
    def _get_condition_multiplier(self, condition: str) -> float:
        """Get price multiplier based on condition"""
        multipliers = {
            "excellent": 1.10,
            "good": 1.00,
            "fair": 0.88,
            "poor": 0.72,
        }
        return multipliers.get(condition.lower(), 1.0)
    
    def _calculate_confidence(
        self, 
        make: str, 
        model: str, 
        year: int, 
        mileage: Optional[int]
    ) -> str:
        """
        Determine estimation confidence level
        """
        # High confidence for popular makes and recent years
        popular_makes = ["Toyota", "Honda", "Ford", "Chevrolet", "Nissan", "Hyundai", "Kia"]
        
        confidence_score = 50  # Base score
        
        if make in popular_makes:
            confidence_score += 20
        
        if self.current_year - year <= 5:
            confidence_score += 15
        
        if mileage is not None:
            confidence_score += 10
        
        if confidence_score >= 80:
            return "high"
        elif confidence_score >= 60:
            return "medium"
        else:
            return "low"
    
    def _generate_notes(
        self, 
        make: str, 
        model: str, 
        year: int, 
        age: int, 
        condition: str
    ) -> str:
        """Generate notes about the estimate"""
        notes = []
        
        if age > 10:
            notes.append("Vehicle is over 10 years old; value varies significantly by condition.")
        
        if make in self.PREMIUM_BRANDS:
            notes.append("Luxury brand typically holds value well but has higher maintenance costs.")
        
        if condition == "excellent":
            notes.append("Excellent condition can command premium pricing.")
        elif condition == "poor":
            notes.append("Poor condition significantly impacts resale value.")
        
        notes.append("Estimate based on market averages. Actual value depends on local market, options, and history.")
        
        return " ".join(notes)

    async def generate_recommendation(
        self,
        make: str,
        model: str,
        year: int,
        mileage: Optional[int] = None,
        trim: Optional[str] = None,
        condition: str = "good"
    ) -> Dict[str, Any]:
        """
        Generate an aggregated price recommendation using external APIs and algorithmic fallback.
        """
        # 1. Get algorithmic base estimate
        algo_estimate = await self.estimate_price(make, model, year, mileage, trim, condition)
        
        base_msrp = self._get_base_value(make, model, trim)
        brand_mult = self.PREMIUM_BRANDS.get(make, 1.0)
        estimated_msrp = round(base_msrp * brand_mult, -2)
        
        # 2. Run pricing adapters concurrently
        tasks = [
            self.edmunds.fetch_price_data(make, model, year),
            self.truecar.fetch_price_data(make, model, year),
            self.autotrader.fetch_price_data(make, model, year),
            self.opendata_soft.fetch_price_data(make, model, year)
        ]
        
        results = await asyncio.gather(*tasks, return_exceptions=True)
        
        # 3. Aggregate data points
        market_averages = [algo_estimate['estimated_value_avg']]
        data_sources_used = ["Algorithmic"]
        
        edmunds_res = results[0]
        if not isinstance(edmunds_res, Exception) and "estimated_market_value" in edmunds_res:
            market_averages.append(edmunds_res["estimated_market_value"])
            data_sources_used.append("Edmunds")
            
        truecar_res = results[1]
        if not isinstance(truecar_res, Exception) and "market_average" in truecar_res:
            market_averages.append(truecar_res["market_average"])
            data_sources_used.append("TrueCar")
            
        autotrader_res = results[2]
        if not isinstance(autotrader_res, Exception) and "average_listing_price" in autotrader_res:
            market_averages.append(autotrader_res["average_listing_price"] * 0.95) # Reduce retail to market
            data_sources_used.append("AutoTrader")
            
        opendata_res = results[3]
        if not isinstance(opendata_res, Exception) and "msrp" in opendata_res and opendata_res["msrp"] > 0:
            estimated_msrp = opendata_res["msrp"]
            data_sources_used.append("OpenDataSoft")
            
        # 4. Calculate Final Aggregated Values
        aggregated_avg = sum(market_averages) / len(market_averages)
        
        # Final bounds based on aggregated average
        condition_mult = self._get_condition_multiplier(condition)
        fair_low = round((aggregated_avg * 0.92) * condition_mult, -2)
        fair_high = round((aggregated_avg * 1.08) * condition_mult, -2)
        
        # Ensure logical bounds
        fair_low = max(fair_low, 1000)
        fair_high = max(fair_high, fair_low + 500)
        
        methodology = f"Aggregated from {len(data_sources_used)} sources: {', '.join(data_sources_used)}."
        if mileage is not None:
             methodology += f" Adjusted for {mileage:,} miles."
             
        vehicle_summary = f"{year} {make} {model}"
        if trim:
            vehicle_summary += f" {trim}"
        if mileage:
            vehicle_summary += f" ({mileage:,} miles)"
            
        return {
            "fair_price_low": float(fair_low),
            "fair_price_high": float(fair_high),
            "msrp": float(estimated_msrp),
            "estimated_avg": float(aggregated_avg * condition_mult),
            "basis": f"Synthesized pricing utilizing {len(data_sources_used)} external APIs with algorithmic smoothing",
            "methodology": methodology,
            "confidence": "high" if len(data_sources_used) >= 3 else algo_estimate["confidence"],
            "vehicle_summary": vehicle_summary,
            "data_sources": data_sources_used
        }


class PriceException(Exception):
    """Custom exception for pricing errors"""
    pass


# Singleton instance
price_service = PriceService()
