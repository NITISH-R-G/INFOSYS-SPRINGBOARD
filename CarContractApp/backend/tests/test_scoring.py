"""
Tests for Scoring Engine - Risk Assessment Framework (Gap 5)
Extended to cover the new assess_risk() method and AutoBenchmarks.
"""
import sys
import os
import unittest

# Add parent directory to path to import app modules
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.services.scoring_engine import ScoringEngine, AutoBenchmarks
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
        self.assertEqual(score, 100)

    def test_overpriced_contract(self):
        """Test score penalty for overpriced contract"""
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
        sla = SLAData(
            buyout_price=17000.0,
            market_value=20000.0,
            apr=5.0
        )
        score, explanation = ScoringEngine.calculate_score(sla, [])
        self.assertEqual(score, 100)  # Capped at 100

        # With APR penalty
        sla_high_apr = SLAData(
            buyout_price=17000.0,
            market_value=20000.0,
            apr=9.0
        )
        score, _ = ScoringEngine.calculate_score(sla_high_apr, [])
        self.assertEqual(score, 90)


class TestRiskAssessment(unittest.TestCase):

    def test_risk_assessment_high_apr(self):
        """APR above 14% should produce HIGH severity"""
        sla = SLAData(apr=15.0)
        result = ScoringEngine.assess_risk(sla, [], contract_type="loan")

        self.assertIn("overall_risk_level", result)
        self.assertIn("risk_items", result)

        apr_items = [r for r in result["risk_items"] if r["category"] == "Interest Rate (APR)"]
        self.assertEqual(len(apr_items), 1)
        self.assertEqual(apr_items[0]["severity"], "high")
        self.assertGreater(apr_items[0]["impact_points"], 0)

    def test_risk_assessment_low_apr(self):
        """APR of 4% should produce LOW severity (below benchmark)"""
        sla = SLAData(apr=4.0)
        result = ScoringEngine.assess_risk(sla, [], contract_type="loan")

        apr_items = [r for r in result["risk_items"] if r["category"] == "Interest Rate (APR)"]
        self.assertEqual(len(apr_items), 1)
        self.assertEqual(apr_items[0]["severity"], "low")
        self.assertEqual(apr_items[0]["impact_points"], 0)

    def test_risk_assessment_combined(self):
        """Multiple risk factors should accumulate correctly"""
        sla = SLAData(
            apr=12.0,
            documentation_fee=800.0,
            mileage_overage_fee=0.35,
            mileage_limit=8000,
        )
        result = ScoringEngine.assess_risk(sla, [], contract_type="lease")

        self.assertGreater(result["total_impact_points"], 20)
        self.assertGreater(len(result["risk_items"]), 2)

    def test_risk_assessment_with_used_vehicle(self):
        """Used vehicle (>1 year old) should use used-car APR benchmarks"""
        sla = SLAData(apr=8.0)
        result = ScoringEngine.assess_risk(sla, [], contract_type="loan", vehicle_year=2022)

        apr_items = [r for r in result["risk_items"] if r["category"] == "Interest Rate (APR)"]
        self.assertEqual(len(apr_items), 1)
        # 8.0% vs used benchmark 7.5% → medium
        self.assertEqual(apr_items[0]["severity"], "medium")

    def test_risk_assessment_market_overprice(self):
        """Contract price 25% above market should be HIGH"""
        sla = SLAData(
            buyout_price=25000.0,
            market_value=20000.0,
        )
        result = ScoringEngine.assess_risk(sla, [], contract_type="loan")

        price_items = [r for r in result["risk_items"] if r["category"] == "Price vs Market Value"]
        self.assertEqual(len(price_items), 1)
        self.assertEqual(price_items[0]["severity"], "high")

    def test_risk_assessment_with_clause_risks(self):
        """High-risk clauses should appear in risk assessment"""
        sla = SLAData(apr=5.0)
        risks = [
            RedFlag(
                clause_text="No refund upon early termination",
                title="Unfair Termination",
                risk_level="high",
                why_flag="No refund",
                risks="Financial loss",
                plain_explanation="You get nothing back",
                suggestion="Negotiate partial refund"
            ),
            RedFlag(
                clause_text="Late fee of $500",
                title="Excessive Late Fee",
                risk_level="medium",
                why_flag="High late fee",
                risks="Penalty risk",
                plain_explanation="Late fee is very high",
                suggestion="Negotiate lower fee"
            ),
        ]
        result = ScoringEngine.assess_risk(sla, risks, contract_type="lease")

        clause_items = [r for r in result["risk_items"] if "Clause" in r["category"]]
        self.assertGreater(len(clause_items), 0)
        self.assertGreater(result["total_impact_points"], 0)

    def test_risk_assessment_overall_low(self):
        """Good contract should have low overall risk"""
        sla = SLAData(
            apr=4.0,
            documentation_fee=300.0,
            mileage_limit=15000,
            buyout_price=20000.0,
            market_value=22000.0,
        )
        result = ScoringEngine.assess_risk(sla, [], contract_type="loan")
        self.assertEqual(result["overall_risk_level"], "low")

    def test_risk_assessment_structure(self):
        """Verify the response structure matches schema"""
        sla = SLAData(apr=10.0, documentation_fee=600.0)
        result = ScoringEngine.assess_risk(sla, [], contract_type="loan")

        self.assertIn("overall_risk_level", result)
        self.assertIn("risk_items", result)
        self.assertIn("total_impact_points", result)
        self.assertIn("summary", result)

        self.assertIn(result["overall_risk_level"], ["low", "medium", "high"])
        self.assertIsInstance(result["risk_items"], list)
        self.assertIsInstance(result["total_impact_points"], int)

        if result["risk_items"]:
            item = result["risk_items"][0]
            self.assertIn("category", item)
            self.assertIn("severity", item)
            self.assertIn("benchmark", item)
            self.assertIn("actual_value", item)
            self.assertIn("impact_points", item)
            self.assertIn("mitigation", item)


if __name__ == '__main__':
    unittest.main()
