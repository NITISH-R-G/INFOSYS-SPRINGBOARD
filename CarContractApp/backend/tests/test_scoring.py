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
from app.models.schemas import SLAData, RedFlag, DCFSFeatures


class TestScoringEngine(unittest.TestCase):

    def setUp(self):
        # A baseline average contract
        self.neutral_sla = SLAData(apr=6.0, buyout_price=20000.0, market_value=20000.0)
        self.neutral_dcfs = DCFSFeatures(
            consumer_obligations_count=5,
            provider_obligations_count=5, # Perfectly balanced obligations
            consumer_liabilities_count=2,
            provider_liabilities_count=2, # Perfectly balanced liabilities
            consumer_termination_rights_score=0.5,
            provider_termination_rights_score=0.5, # Balanced termination rights
            penalty_intensity_score=1.0, # Standard minor penalties
            hidden_risk_index=1.0, # Minor ambiguity
            protection_clauses_extracted=5,
            expected_protections_baseline=5
        )

    def test_dcfs_fallback(self):
        """Test fallback when DCFS features are missing"""
        score, explanation = ScoringEngine.calculate_score(self.neutral_sla)
        self.assertEqual(score, 60)
        self.assertIn("Missing DCFS Features", explanation)

    def test_neutral_contract_anchoring(self):
        """Test that a perfectly balanced contract scores near the 60 anchor"""
        score, explanation = ScoringEngine.calculate_score(self.neutral_sla, dcfs_features=self.neutral_dcfs)
        self.assertGreaterEqual(score, 75)
        self.assertLessEqual(score, 90)
        self.assertIn("Excellent", explanation)

    def test_excellent_contract_ceiling(self):
        """Test an exceptionally fair, balanced contract with no penalties"""
        excellent_sla = SLAData(apr=4.0, buyout_price=18000.0, market_value=20000.0) # Great APR, below market
        excellent_dcfs = DCFSFeatures(
            consumer_obligations_count=5,
            provider_obligations_count=5, # Perfectly symmetric
            consumer_liabilities_count=2,
            provider_liabilities_count=2, # Perfectly symmetric
            consumer_termination_rights_score=1.0, 
            provider_termination_rights_score=1.0, 
            penalty_intensity_score=0.0, # Zero penalties
            hidden_risk_index=0.0, # Totally transparent
            protection_clauses_extracted=8,
            expected_protections_baseline=5
        )
        score, explanation = ScoringEngine.calculate_score(excellent_sla, dcfs_features=excellent_dcfs)
        self.assertGreaterEqual(score, 88) # Should reach high 80s/90s

    def test_high_risk_asymmetric_contract(self):
        """Test a predatory contract with high penalties and asymmetry"""
        poor_sla = SLAData(apr=15.0, buyout_price=25000.0, market_value=20000.0) # Terrible APR, overpriced
        poor_dcfs = DCFSFeatures(
            consumer_obligations_count=10,
            provider_obligations_count=2, # Heavy consumer asymmetry
            consumer_liabilities_count=8,
            provider_liabilities_count=0, # Heavy consumer asymmetry
            consumer_termination_rights_score=0.0, 
            provider_termination_rights_score=1.0, 
            penalty_intensity_score=8.5, # Severe penalties and acceleration
            hidden_risk_index=9.0, # Highly opaque
            protection_clauses_extracted=1,
            expected_protections_baseline=5
        )
        score, explanation = ScoringEngine.calculate_score(poor_sla, dcfs_features=poor_dcfs)
        self.assertLessEqual(score, 50) # Crushed by asymmetry and penalties
        self.assertIn("High Risk", explanation)

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
