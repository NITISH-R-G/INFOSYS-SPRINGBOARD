"""
Scoring Engine
Deterministic logical scoring for car contracts
Includes structured Risk Assessment Framework (Gap 5)
"""
from ..models.schemas import SLAData, RedFlag
from typing import List, Tuple, Dict, Any, Optional


# ==================== Automotive Benchmarks ====================

class AutoBenchmarks:
    """Industry-standard benchmarks for auto lease/loan evaluation"""

    # APR Benchmarks (as of 2025–2026 averages)
    APR_NEW_EXCELLENT = 4.5    # Excellent credit, new car
    APR_NEW_GOOD = 6.0         # Good credit, new car
    APR_NEW_FAIR = 9.0         # Fair credit, new car
    APR_USED_EXCELLENT = 5.5
    APR_USED_GOOD = 7.5
    APR_USED_FAIR = 10.0
    APR_SUBPRIME = 14.0        # Subprime threshold

    # Fee Benchmarks
    DOC_FEE_MAX = 500          # Max reasonable documentation fee
    ACQUISITION_FEE_MAX = 900  # Max reasonable lease acquisition fee
    DISPOSITION_FEE_MAX = 450  # Max reasonable disposition fee

    # Mileage Benchmarks
    MILEAGE_OVERAGE_LOW = 0.15   # $/mile — low end
    MILEAGE_OVERAGE_HIGH = 0.30  # $/mile — high end (above is excessive)
    ANNUAL_MILEAGE_LOW = 10000
    ANNUAL_MILEAGE_STANDARD = 12000
    ANNUAL_MILEAGE_HIGH = 15000

    # Residual Value (% of MSRP after 3 years)
    RESIDUAL_LOW = 0.40   # Below this is poor residual
    RESIDUAL_FAIR = 0.50
    RESIDUAL_GOOD = 0.58

    # Early Termination
    EARLY_TERM_MONTHS_MAX = 6  # Max reasonable penalty in months-equivalent


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
        if sla.apr is not None:
            diff = sla.apr - AutoBenchmarks.APR_NEW_GOOD
            if diff > 0:
                points = min(30, int(diff * 5))
                score -= points
                penalties.append(f"High APR ({sla.apr}%) reduced score by {points} pts")

        # 2. Hidden Fees Impact (Weight: 20)
        if sla.documentation_fee and sla.documentation_fee > AutoBenchmarks.DOC_FEE_MAX:
            score -= 10
            penalties.append("Excessive documentation fee")

        if contract_type == "lease":
            if sla.acquisition_fee and sla.acquisition_fee > AutoBenchmarks.ACQUISITION_FEE_MAX:
                score -= 5
                penalties.append("High acquisition fee")
            if sla.disposition_fee and sla.disposition_fee > AutoBenchmarks.DISPOSITION_FEE_MAX:
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
        if sla.market_value and sla.buyout_price:
            ratio = sla.buyout_price / sla.market_value
            if ratio > 1.10:
                overage_pct = int(round((ratio - 1.0) * 100))
                points = min(25, (overage_pct - 10) * 2)
                score -= points
                penalties.append(f"Price is {overage_pct}% above market value")
            elif ratio < 0.90:
                score += 5

        elif sla.market_value and contract_type == "lease" and sla.monthly_payment and sla.term_months:
            pass  # Complex lease cost vs market — skipped for simplicity

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

    # ==================== Structured Risk Assessment (Gap 5) ====================

    @staticmethod
    def assess_risk(
        sla: SLAData,
        risks: List[RedFlag],
        contract_type: str = "loan",
        vehicle_year: Optional[int] = None
    ) -> Dict[str, Any]:
        """
        Generate a structured risk assessment report with benchmark comparisons.

        Returns a dict matching the RiskAssessmentResult schema:
        {
            "overall_risk_level": "low" | "medium" | "high",
            "risk_items": [ ... ],
            "total_impact_points": int,
            "summary": str
        }
        """
        risk_items: List[Dict[str, Any]] = []
        total_impact = 0
        is_used = vehicle_year and (2026 - vehicle_year) > 1

        # --- 1. APR Risk ---
        if sla.apr is not None:
            if is_used:
                benchmark = AutoBenchmarks.APR_USED_GOOD
                benchmark_label = f"≤{benchmark}% (used vehicle, good credit)"
            else:
                benchmark = AutoBenchmarks.APR_NEW_GOOD
                benchmark_label = f"≤{benchmark}% (new vehicle, good credit)"

            if sla.apr >= AutoBenchmarks.APR_SUBPRIME:
                severity = "high"
                impact = 20
                mitigation = (
                    "Your APR is in subprime territory. Consider improving your credit score, "
                    "getting pre-approved from a credit union, or adding a co-signer to negotiate a lower rate."
                )
            elif sla.apr > benchmark + 3:
                severity = "high"
                impact = 15
                mitigation = (
                    f"APR is significantly above the {benchmark}% benchmark. "
                    "Shop rates at 3+ lenders and use competing offers as leverage."
                )
            elif sla.apr > benchmark:
                severity = "medium"
                impact = 8
                mitigation = (
                    f"APR is above the {benchmark}% benchmark. "
                    "Request a rate match or consider a shorter loan term for a lower rate."
                )
            else:
                severity = "low"
                impact = 0
                mitigation = "APR is within or below the market benchmark. No action needed."

            risk_items.append({
                "category": "Interest Rate (APR)",
                "severity": severity,
                "benchmark": benchmark_label,
                "actual_value": f"{sla.apr}%",
                "impact_points": impact,
                "mitigation": mitigation
            })
            total_impact += impact

        # --- 2. Documentation Fee ---
        if sla.documentation_fee is not None:
            benchmark_label = f"≤${AutoBenchmarks.DOC_FEE_MAX}"
            if sla.documentation_fee > AutoBenchmarks.DOC_FEE_MAX * 1.5:
                severity = "high"
                impact = 10
                mitigation = (
                    f"Documentation fee of ${sla.documentation_fee:.0f} is far above the "
                    f"${AutoBenchmarks.DOC_FEE_MAX} industry average. Negotiate this down or ask for it to be waived."
                )
            elif sla.documentation_fee > AutoBenchmarks.DOC_FEE_MAX:
                severity = "medium"
                impact = 5
                mitigation = (
                    f"Fee of ${sla.documentation_fee:.0f} exceeds the ${AutoBenchmarks.DOC_FEE_MAX} benchmark. "
                    "Some states cap doc fees — check your local regulations."
                )
            else:
                severity = "low"
                impact = 0
                mitigation = "Documentation fee is within the acceptable range."

            risk_items.append({
                "category": "Documentation Fee",
                "severity": severity,
                "benchmark": benchmark_label,
                "actual_value": f"${sla.documentation_fee:.0f}",
                "impact_points": impact,
                "mitigation": mitigation
            })
            total_impact += impact

        # --- 3. Mileage Overage Fee (Leases) ---
        if contract_type == "lease" and sla.mileage_overage_fee is not None:
            benchmark_label = f"${AutoBenchmarks.MILEAGE_OVERAGE_LOW}–${AutoBenchmarks.MILEAGE_OVERAGE_HIGH}/mile"
            if sla.mileage_overage_fee > AutoBenchmarks.MILEAGE_OVERAGE_HIGH:
                severity = "high"
                impact = 12
                mitigation = (
                    f"Overage fee of ${sla.mileage_overage_fee}/mile exceeds the market range. "
                    "Negotiate a higher mileage allowance upfront — it's cheaper than overage fees."
                )
            elif sla.mileage_overage_fee > AutoBenchmarks.MILEAGE_OVERAGE_LOW:
                severity = "medium"
                impact = 4
                mitigation = "Overage fee is within range but on the higher side. Consider a higher mileage tier."
            else:
                severity = "low"
                impact = 0
                mitigation = "Mileage overage fee is competitive."

            risk_items.append({
                "category": "Mileage Overage Fee",
                "severity": severity,
                "benchmark": benchmark_label,
                "actual_value": f"${sla.mileage_overage_fee}/mile",
                "impact_points": impact,
                "mitigation": mitigation
            })
            total_impact += impact

        # --- 4. Mileage Limit (Leases) ---
        if contract_type == "lease" and sla.mileage_limit is not None:
            benchmark_label = f"{AutoBenchmarks.ANNUAL_MILEAGE_STANDARD:,}+ miles/year"
            if sla.mileage_limit < AutoBenchmarks.ANNUAL_MILEAGE_LOW:
                severity = "high"
                impact = 10
                mitigation = (
                    f"Mileage limit of {sla.mileage_limit:,} miles/year is restrictive. "
                    "Average drivers do 12,000–15,000 miles/year. Negotiate a higher limit."
                )
            elif sla.mileage_limit < AutoBenchmarks.ANNUAL_MILEAGE_STANDARD:
                severity = "medium"
                impact = 5
                mitigation = (
                    "Mileage limit is below the 12,000 miles/year standard. "
                    "Evaluate your driving habits before accepting."
                )
            else:
                severity = "low"
                impact = 0
                mitigation = "Mileage allowance is adequate for most drivers."

            risk_items.append({
                "category": "Annual Mileage Limit",
                "severity": severity,
                "benchmark": benchmark_label,
                "actual_value": f"{sla.mileage_limit:,} miles/year",
                "impact_points": impact,
                "mitigation": mitigation
            })
            total_impact += impact

        # --- 5. Residual Value (Leases) ---
        if contract_type == "lease" and sla.residual_value is not None and sla.market_value:
            residual_pct = sla.residual_value / sla.market_value
            benchmark_label = f"≥{AutoBenchmarks.RESIDUAL_FAIR * 100:.0f}% of market value"
            if residual_pct < AutoBenchmarks.RESIDUAL_LOW:
                severity = "high"
                impact = 12
                mitigation = (
                    f"Residual value is only {residual_pct * 100:.0f}% of market value — significantly below "
                    "the 50% benchmark. This inflates your monthly payment. Negotiate a higher residual."
                )
            elif residual_pct < AutoBenchmarks.RESIDUAL_FAIR:
                severity = "medium"
                impact = 6
                mitigation = (
                    f"Residual at {residual_pct * 100:.0f}% is below the fair 50% benchmark. "
                    "Compare with other dealer offers."
                )
            else:
                severity = "low"
                impact = 0
                mitigation = "Residual value is competitive — this helps keep payments lower."

            risk_items.append({
                "category": "Residual Value",
                "severity": severity,
                "benchmark": benchmark_label,
                "actual_value": f"{residual_pct * 100:.0f}% (${sla.residual_value:,.0f})",
                "impact_points": impact,
                "mitigation": mitigation
            })
            total_impact += impact

        # --- 6. Lease-specific Fees ---
        if contract_type == "lease":
            if sla.acquisition_fee is not None:
                benchmark_label = f"≤${AutoBenchmarks.ACQUISITION_FEE_MAX}"
                if sla.acquisition_fee > AutoBenchmarks.ACQUISITION_FEE_MAX:
                    severity = "medium"
                    impact = 5
                    mitigation = (
                        f"Acquisition fee of ${sla.acquisition_fee:.0f} exceeds the "
                        f"${AutoBenchmarks.ACQUISITION_FEE_MAX} benchmark. Ask if this is negotiable."
                    )
                else:
                    severity = "low"
                    impact = 0
                    mitigation = "Acquisition fee is within the standard range."

                risk_items.append({
                    "category": "Acquisition Fee",
                    "severity": severity,
                    "benchmark": benchmark_label,
                    "actual_value": f"${sla.acquisition_fee:.0f}",
                    "impact_points": impact,
                    "mitigation": mitigation
                })
                total_impact += impact

            if sla.disposition_fee is not None:
                benchmark_label = f"≤${AutoBenchmarks.DISPOSITION_FEE_MAX}"
                if sla.disposition_fee > AutoBenchmarks.DISPOSITION_FEE_MAX:
                    severity = "medium"
                    impact = 5
                    mitigation = (
                        f"Disposition fee of ${sla.disposition_fee:.0f} is above average. "
                        "You can avoid this by purchasing the vehicle at lease end."
                    )
                else:
                    severity = "low"
                    impact = 0
                    mitigation = "Disposition fee is within the standard range."

                risk_items.append({
                    "category": "Disposition Fee",
                    "severity": severity,
                    "benchmark": benchmark_label,
                    "actual_value": f"${sla.disposition_fee:.0f}",
                    "impact_points": impact,
                    "mitigation": mitigation
                })
                total_impact += impact

        # --- 7. Market Value vs Contract Price ---
        if sla.market_value and sla.buyout_price:
            ratio = sla.buyout_price / sla.market_value
            overage_pct = (ratio - 1.0) * 100
            benchmark_label = "Within ±10% of fair market value"
            if ratio > 1.20:
                severity = "high"
                impact = 15
                mitigation = (
                    f"Contract price is {overage_pct:.0f}% above market value. "
                    "Use Kelley Blue Book or Edmunds pricing as leverage to negotiate down."
                )
            elif ratio > 1.10:
                severity = "medium"
                impact = 8
                mitigation = (
                    f"Contract price is {overage_pct:.0f}% above market. "
                    "There's room to negotiate — present competing dealer quotes."
                )
            elif ratio < 0.90:
                severity = "low"
                impact = 0
                mitigation = "Excellent deal — the price is below market value."
            else:
                severity = "low"
                impact = 0
                mitigation = "Price is within the fair market range."

            risk_items.append({
                "category": "Price vs Market Value",
                "severity": severity,
                "benchmark": benchmark_label,
                "actual_value": f"${sla.buyout_price:,.0f} ({overage_pct:+.0f}% vs market)",
                "impact_points": impact,
                "mitigation": mitigation
            })
            total_impact += impact

        # --- 8. Clause-Level Risks from LLM ---
        high_clause_risks = [r for r in risks if r.risk_level.lower() == "high"]
        med_clause_risks = [r for r in risks if r.risk_level.lower() == "medium"]

        if high_clause_risks:
            impact = len(high_clause_risks) * 10
            risk_items.append({
                "category": "High-Risk Contract Clauses",
                "severity": "high",
                "benchmark": "0 high-risk clauses",
                "actual_value": f"{len(high_clause_risks)} clause(s) flagged",
                "impact_points": impact,
                "mitigation": (
                    "Review these clauses with a legal professional before signing: "
                    + "; ".join(r.title for r in high_clause_risks[:3])
                )
            })
            total_impact += impact

        if med_clause_risks:
            impact = len(med_clause_risks) * 4
            risk_items.append({
                "category": "Medium-Risk Contract Clauses",
                "severity": "medium",
                "benchmark": "Minimal medium-risk clauses",
                "actual_value": f"{len(med_clause_risks)} clause(s) flagged",
                "impact_points": impact,
                "mitigation": (
                    "These clauses deserve attention: "
                    + "; ".join(r.title for r in med_clause_risks[:3])
                )
            })
            total_impact += impact

        # --- Determine Overall Risk Level ---
        high_count = sum(1 for item in risk_items if item["severity"] == "high")
        med_count = sum(1 for item in risk_items if item["severity"] == "medium")

        if high_count >= 2 or total_impact >= 40:
            overall = "high"
            summary = (
                f"This contract has significant risk factors ({high_count} high-severity items). "
                "Strongly consider negotiating key terms before signing."
            )
        elif high_count >= 1 or med_count >= 3 or total_impact >= 20:
            overall = "medium"
            summary = (
                f"This contract has moderate risk ({med_count} medium + {high_count} high items). "
                "Review the flagged items and negotiate where possible."
            )
        else:
            overall = "low"
            summary = "This contract's terms are within acceptable market benchmarks. Low overall risk."

        return {
            "overall_risk_level": overall,
            "risk_items": risk_items,
            "total_impact_points": total_impact,
            "summary": summary
        }
