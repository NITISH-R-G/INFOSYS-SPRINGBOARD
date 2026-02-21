
import sys
import os
import unittest
from decimal import Decimal

# Add parent directory to path to import app modules
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.services.scoring_engine import ScoringEngine
from app.models.schemas import SLAData, RedFlag

class TestScoringEngine(unittest.TestCase):
    
    def test_fair_market_price(self):
        """Test score when price matches market value"""
        sla = SLAData(
            buyout_price=20000.0,
            market_value=20000.0,
            apr=5.0
        )
        score, explanation = ScoringEngine.calculate_score(sla, [])
        # Base 100, no APR penalty (5 < 7), no price penalty
        self.assertEqual(score, 100)
        
    def test_overpriced_contract(self):
        """Test score penalty for overpriced contract"""
        # 120% of market value (20% overage)
        # Logic: >10% buffer. 20% - 10% = 10% over threshold.
        # Penalty: 2 pts per %. 10 * 2 = 20 pts penalty.
        sla = SLAData(
            buyout_price=24000.0,
            market_value=20000.0,
            apr=5.0
        )
        score, explanation = ScoringEngine.calculate_score(sla, [])
        self.assertEqual(score, 80)
        self.assertIn("Price is 20% above market value", explanation)
        
    def test_good_deal_bonus(self):
        """Test score bonus for good deal"""
        # 85% of market value (< 90%)
        sla = SLAData(
            buyout_price=17000.0,
            market_value=20000.0,
            apr=5.0
        )
        score, explanation = ScoringEngine.calculate_score(sla, [])
        # Base 100 + 5 bonus = 100 (capped)
        self.assertEqual(score, 100)
        
        # Test with some penalties to see bonus effect
        # APR 9% (2% over 7% = -10 pts) -> 90 base
        # Good deal (+5) -> 95 total
        sla_high_apr = SLAData(
            buyout_price=17000.0,
            market_value=20000.0,
            apr=9.0
        )
        score, _ = ScoringEngine.calculate_score(sla_high_apr, [])
        self.assertEqual(score, 95)

if __name__ == '__main__':
    unittest.main()
