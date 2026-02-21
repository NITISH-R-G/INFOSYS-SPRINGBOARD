"""
Scoring Engine
Deterministic logical scoring for car contracts
"""
from ..models.schemas import SLAData, RedFlag
from typing import List, Tuple

class ScoringEngine:
    
    @staticmethod
    def calculate_score(sla: SLAData, risks: List[RedFlag], contract_type: str = "loan") -> Tuple[int, str]:
        """
        Calculate a deterministic fairness score (0-100)
        Returns: (score, explanation)
        """
        score = 100
        penalties = []

        # 1. APR / Rent Charge Impact (Weight: 30)
        # Benchmark: 6% for new cars, 9% for used. Using 7% as generic conservative benchmark.
        if sla.apr is not None:
            # Linear penalty: -5 points for every 1% above 7%
            diff = sla.apr - 7.0
            if diff > 0:
                points = min(30, int(diff * 5))
                score -= points
                penalties.append(f"High APR ({sla.apr}%) reduced score by {points} pts")
        
        # 2. Hidden Fees Impact (Weight: 20)
        # Excessive doc fee (> 500)
        if sla.documentation_fee and sla.documentation_fee > 500:
            score -= 10
            penalties.append("Excessive documentation fee")
            
        # Lease specific fees
        if contract_type == "lease":
            if sla.acquisition_fee and sla.acquisition_fee > 900:
                score -= 5
                penalties.append("High acquisition fee")
            if sla.disposition_fee and sla.disposition_fee > 500:
                score -= 5
                penalties.append("High disposition fee")

        # 3. Risk Flag Impact (Weight: 50)
        risk_counts = {"high": 0, "medium": 0, "low": 0}
        
        for flag in risks:
            level = flag.risk_level.lower()
            if level == "high":
                score -= 15
                risk_counts["high"] += 1
            elif level == "medium":
                score -= 8
                risk_counts["medium"] += 1
            elif level == "low":
                score -= 2
                risk_counts["low"] += 1

        if risk_counts["high"] > 0:
            penalties.append(f"{risk_counts['high']} high-risk clauses detected")

        # 4. Market Value Impact (Price-to-Value)
        # Using 10% tolerance buffering
        if sla.market_value and sla.buyout_price:
            ratio = sla.buyout_price / sla.market_value
            if ratio > 1.10: # >10% over market
                overage_pct = int(round((ratio - 1.0) * 100))
                points = min(25, (overage_pct - 10) * 2) # 2 pts per % over 10%
                score -= points
                penalties.append(f"Price is {overage_pct}% above market value")
            elif ratio < 0.90: # >10% under market (Good deal)
                score += 5 # Bonus
        
        # Check Total Lease Cost vs Market (for leases)
        elif sla.market_value and contract_type == "lease" and sla.monthly_payment and sla.term_months:
            # Approx total cost (excluding down payment for simplicity/or include it)
            total_cost = (sla.monthly_payment * sla.term_months) + (sla.down_payment or 0)
            # Lease verification is complex, but if Total Cost > 120% of Value (approx cap cost + rent), flag it
            # Simple heuristic: Depreciation + Rent. If Total > Value * 0.6 (rule of thumb for 3 years), check it.
            # For now, let's stick to Buyout Price if available, or just skip lease market scoring unless we have Cap Cost.
            pass

        # Clamp score
        final_score = max(0, min(100, score))
        
        # Generate Explanation
        if final_score >= 90 and not penalties:
            explanation = "Excellent Deal. Terms are competitive with minimal risks."
        elif final_score >= 70:
            base = "Good Deal" if final_score >= 80 else "Fair Deal"
            explanation = f"{base}. " + "; ".join(penalties[:2]) if penalties else f"{base}. Standard terms."
        else:
            explanation = "Poor Deal. " + "; ".join(penalties[:3])

        return final_score, explanation
