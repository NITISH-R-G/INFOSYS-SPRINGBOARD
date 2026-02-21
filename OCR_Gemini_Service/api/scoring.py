from typing import Dict, Any, List

class FairnessScorer:
    """
    Computes a deterministic fairness score for a vehicle contract.
    """
    
    BASE_SCORE = 100

    def __init__(self):
        pass

    def evaluate_contract(self, 
                          contract_price: float, 
                          market_average: float, 
                          apr: float = None, 
                          fees: float = 0.0) -> Dict[str, Any]:
        """
        Evaluate and return a score and penalties breakdown based on input parameters.
        Score ranges from 0 to 100.
        """
        score = self.BASE_SCORE
        penalties: List[Dict[str, Any]] = []
        
        # 1. Price Deviation Penalty
        if contract_price > market_average:
            # E.g., for every 1% over market average, deduct 2 points.
            deviation_pct = (contract_price - market_average) / market_average
            penalty_points = int(deviation_pct * 100 * 2) 
            if penalty_points > 0:
                score -= penalty_points
                penalties.append({
                    "category": "Price",
                    "reason": f"Contract price is {deviation_pct*100:.1f}% above market average.",
                    "points_deducted": penalty_points
                })
        else:
            # Reward slightly if under market (up to a max of 100 total score)
            pass 

        # 2. APR Penalty (Assuming typical good APR is <= 6.0%)
        # Here we hardcode typical; in reality, this might depend on credit score provided.
        TYPICAL_MAX_APR = 6.0
        if apr is not None and apr > TYPICAL_MAX_APR:
            # Deduct 3 points for every 1% above 6%
            apr_penalty = int((apr - TYPICAL_MAX_APR) * 3)
            if apr_penalty > 0:
                score -= apr_penalty
                penalties.append({
                    "category": "Financing",
                    "reason": f"APR of {apr}% is higher than typical optimal rates ({TYPICAL_MAX_APR}%).",
                    "points_deducted": apr_penalty
                })
        
        # 3. Fees Penalty
        # Assuming acceptable doc/processing fees max out around $800
        TYPICAL_MAX_FEES = 800.0
        if fees > TYPICAL_MAX_FEES:
            # Deduct 1 point for every $100 over the typical limit
            fee_penalty = int((fees - TYPICAL_MAX_FEES) / 100)
            if fee_penalty > 0:
                score -= fee_penalty
                penalties.append({
                    "category": "Fees",
                    "reason": f"Total fees (${fees:.2f}) exceed typical averages.",
                    "points_deducted": fee_penalty
                })

        # Bounding the score between 0 and 100
        score = max(0, min(100, score))
        
        # Determine verbal tier
        tier = "Excellent"
        if score < 60:
            tier = "Poor"
        elif score < 80:
            tier = "Fair"
        elif score < 90:
            tier = "Good"

        return {
            "score": score,
            "tier": tier,
            "penalties": penalties,
            "metrics_evaluated": {
                "contract_price": contract_price,
                "market_average": market_average,
                "apr": apr,
                "fees": fees
            }
        }
