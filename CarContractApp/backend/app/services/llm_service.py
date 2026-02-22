"""
LLM Service
Handles AI-powered contract analysis using Google Gemini
"""
import json
import re
import logging
from typing import Optional, Dict, Any
import google.generativeai as genai
from ..config import settings
from ..models.schemas import SLAData, ContractAnalysisResult, RedFlag

logger = logging.getLogger(__name__)


class LLMService:
    """Service for LLM-powered contract analysis"""
    
    def __init__(self):
        if settings.GEMINI_API_KEY:
            logger.info("LLM Service: Gemini API key configured.")
            genai.configure(api_key=settings.GEMINI_API_KEY)
            self.model = genai.GenerativeModel(
                'gemini-flash-latest',
                generation_config={"response_mime_type": "application/json"}
            )
        else:
            logger.warning("LLM Service: No Gemini API key found in settings.")
            self.model = None
    
    def _ensure_model(self):
        """Ensure model is configured"""
        if not self.model:
            raise LLMException("Gemini API key not configured")
    
    async def analyze_contract(self, contract_text: str, contract_type: Optional[str] = None) -> ContractAnalysisResult:
        """
        Analyze a contract and extract SLA data and red flags.
        Fairness score is calculated deterministically by ScoringEngine.
        Handles rate limits with exponential backoff.
        """
        self._ensure_model()
        
        logger.info("Starting contract analysis via Gemini...")
        
        prompt = self._build_analysis_prompt(contract_text, contract_type)
        
        # Retry parameters
        max_retries = 3
        base_delay = 5  # Start with 5 seconds (Free tier needs more time)
        
        for attempt in range(max_retries):
            try:
                response = self.model.generate_content(prompt)
                result = self._parse_analysis_response(response.text)
                return result
            except Exception as e:
                # Check for 429 Resource Exhausted or quota errors
                error_str = str(e).lower()
                if "429" in error_str or "quota" in error_str or "resource exhausted" in error_str:
                    if attempt < max_retries - 1:
                        wait_time = base_delay * (2 ** attempt)  # 5s, 10s, 20s
                        logger.warning(f"Rate limit hit. Retrying in {wait_time} seconds...")
                        import asyncio
                        await asyncio.sleep(wait_time)
                        continue
                
                # If not a rate limit, or max retries reached
                raise LLMException(f"Contract analysis failed: {str(e)}")
    
    def _build_analysis_prompt(self, contract_text: str, contract_type: Optional[str] = None) -> str:
        """Build the prompt for contract analysis"""
        
        type_hint = ""
        if contract_type:
            type_hint = f"This appears to be a {contract_type} contract. "
        
        prompt = f"""You are an AI legal document analyzer specialized in vehicle contracts (Lease, Loan, and Sale Agreements).
{type_hint}

Your task is to analyze the uploaded document and extract structured information.

IMPORTANT RULES:
1. **Vehicle Details**: You MUST extract Make, Model, Year, and VIN. Look for them in the header, first paragraph, or vehicle description section. Do not return "Not Mentioned" if the car name is in the text (e.g. "Hyundai i20").
2. **Sale Price**: If this is a Sale Agreement, the "Total Sale Price" OR "Purchase Price" must be extracted into the `purchase_price_or_formula` field under `ownership_terms`.
3. **Inference**: You are allowed to infer fields like "Make" and "Model" from the full vehicle name.
4. **Missing Data**: Only return "Not Mentioned" if the information is TRULY absent.

EXAMPLE INPUT:
"Sale Agreement for 2022 Tesla Model 3 (VIN: 5YJ...). Seller agrees to sell for Total Price of $45,000."

EXAMPLE OUTPUT (Relevant Fields):
{{
  "vehicle_details": {{
    "make": "Tesla",
    "model": "Model 3",
    "manufacturing_year": "2022",
    "vin": "5YJ..."
  }},
  "ownership_terms": {{
    "purchase_price_or_formula": "$45,000"
  }},
  "lease_payment_terms": {{
    "monthly_payment_amount": "Not Mentioned" 
  }}
}}

Extract and organize the information into the following structured JSON format.

--------------------------------------------

0. Dealer Information (Key: dealer_information)
- Dealer Name (e.g., City Auto Group)
- Contact Email (e.g., sales@cityauto.com)
- Contact Phone (e.g., 555-0123)

1. Vehicle Details (Key: vehicle_details)
- Make
- Model
- Variant / Trim
- Manufacturing Year
- Vehicle Identification Number (VIN)
- Registration Number
- Vehicle Condition at Delivery 

2. Lease Payment Terms (Key: lease_payment_terms)
- Monthly Payment Amount (or EMI for Loans)
- Security Deposit / Down Payment
- Payment Due Date
- Late Payment Penalties
- Taxes and Additional Charges 

3. Lease Duration (Key: lease_duration)
- Lease Start Date (or Sale Date)
- Lease End Date
- Total Lease Period 

4. Mileage / Usage Limits (Key: mileage_usage_limits)
- Allowed Mileage Limit
- Excess Mileage Charges 

5. Maintenance and Repair Responsibilities (Key: maintenance_responsibilities)
- Regular Maintenance Responsibility (Lessor or Lessee)
- Repair Cost Responsibility
- Modification Restrictions
- Vehicle Condition Requirements 

6. Insurance Requirements (Key: insurance_requirements)
- Required Insurance Type
- Insurance Payment Responsibility
- Accident / Damage Liability Terms 

7. Damage and Wear Conditions (Key: damage_and_wear_conditions)
- Definition of Normal Wear and Tear
- Excess Damage Charges
- Return Inspection Process 

8. Early Termination Terms (Key: early_termination_terms)
- Early Termination Allowed (Yes/No)
- Termination Charges
- Cancellation Conditions
- Contract Breach Consequences 

9. Ownership Terms (Key: ownership_terms)
- Vehicle Ownership Holder
- End of Lease Purchase Option (Yes/No)
- Purchase Price or Formula (EXTRACT SALE PRICE HERE for Sale Agreements)
- Vehicle Return Conditions 

10. Usage Restrictions (Key: usage_restrictions)
- Authorized Drivers
- Commercial Use Restrictions
- Geographic Usage Restrictions 

11. Default and Legal Clauses (Key: default_and_legal_clauses)
- Default Conditions
- Repossession Rights
- Dispute Resolution Method 

12. End of Lease Process (Key: end_of_lease_process)
- Return Procedure
- Renewal Options
- Final Settlement Terms 

--------------------------------------------

Output Rules:

- Return ONLY valid JSON
- Do not include explanations or commentary
- Preserve original currency values and units
- Extract dates in ISO format (YYYY-MM-DD) if possible
- Highlight risky or unfavorable clauses inside a separate field called "risk_flags" within each section.

Risk Flag Format:
"risk_flags": [
  {{
    "clause": "Extracted clause text",
    "risk_level": "high | medium | low",
    "reason": "Why this clause may be risky for the user"
  }}
]

Risk Level Guidelines (use automotive benchmarks):
- "high": APR above 14%, excessive fees (>$750 doc fee), mileage under 10k/yr, no early termination option, unfair repossession terms
- "medium": APR 7-14%, fees above $500, mileage 10-12k/yr, restrictive modification clauses
- "low": Minor concerns, standard industry terms that slightly favor the dealer/lender

Also include a top-level "missing_sections" list and a "summary" (summarize main terms like Price, Vehicle, Parties).

IMPORTANT: Detect the `currency_code` (e.g. INR, USD) from context and add it to the top level.

CONTRACT TEXT:
---
{contract_text}
---
"""
        return prompt
    
    def _parse_analysis_response(self, response_text: str) -> ContractAnalysisResult:
        """Parse LLM response and calculate deterministic score"""
        from .scoring_engine import ScoringEngine  # Import here to avoid circular dep
        from ..models.schemas import DetailedAnalysis, RedFlag, SLAData
        
        try:
            # Clean up response
            clean_text = response_text.strip()
            if clean_text.startswith("```"):
                clean_text = re.sub(r'^```\w*\n?', '', clean_text)
                clean_text = re.sub(r'\n?```$', '', clean_text)
            
            data = json.loads(clean_text)
            
            # Check for Dealer Information 
            if "dealer_information" in data:
                dealer_info = data["dealer_information"]
                if isinstance(dealer_info, dict):
                    data["dealer_information"] = {
                        "dealer_name": str(dealer_info.get("Dealer Name", dealer_info.get("dealer_name", "Not Mentioned"))),
                        "contact_email": str(dealer_info.get("Contact Email", dealer_info.get("contact_email", "Not Mentioned"))),
                        "contact_phone": str(dealer_info.get("Contact Phone", dealer_info.get("contact_phone", "Not Mentioned"))),
                        "risk_flags": dealer_info.get("risk_flags", [])
                    }

            # Map Detailed Analysis to Pydantic Model
            detailed = DetailedAnalysis(**data)
            
            # Map to legacy SLAData for backward compatibility (best effort mapping)
            def parse_float(val):
                if not val or val == "Not Mentioned": return None
                try:
                    clean = re.sub(r'[^\d.]', '', str(val))
                    return float(clean)
                except:
                    return None
            
            def parse_int(val):
                if not val or val == "Not Mentioned": return None
                try:
                    # simplistic extraction strictly for digits
                    clean = re.sub(r'[^\d]', '', str(val))
                    return int(clean)
                except:
                    return None

            pay_terms = data.get("lease_payment_terms", {})
            duration = data.get("lease_duration", {})
            mileage = data.get("mileage_usage_limits", {})
            term_terms = data.get("early_termination_terms", {})
            ownership = data.get("ownership_terms", {})
            
            sla_data = SLAData(
                currency_code=data.get("currency_code", "USD"),
                monthly_payment=parse_float(pay_terms.get("monthly_payment_amount")),
                down_payment=parse_float(pay_terms.get("security_deposit")),
                mileage_limit=parse_int(mileage.get("allowed_mileage_limit")),
                early_termination_fee=term_terms.get("termination_charges"),
                buyout_price=parse_float(ownership.get("purchase_price_or_formula")),
            )

            # Consolidate Red Flags from all sections
            red_flags_objs = []
            red_flags_raw = []
            
            sections = [
                "vehicle_details", "lease_payment_terms", "lease_duration", "mileage_usage_limits",
                "maintenance_responsibilities", "insurance_requirements", "damage_and_wear_conditions",
                "early_termination_terms", "ownership_terms", "usage_restrictions", "default_and_legal_clauses",
                "end_of_lease_process"
            ]
            
            for section in sections:
                section_data = data.get(section, {})
                risks = section_data.get("risk_flags", [])
                for risk in risks:
                    # Handle both dict and object if Pydantic parsed it
                    clause = risk.get("clause", "Unknown") if isinstance(risk, dict) else risk.clause
                    reason = risk.get("reason", "Potential issue") if isinstance(risk, dict) else risk.reason
                    
                    # Use LLM-provided risk_level, fallback to "medium"
                    llm_risk_level = (
                        risk.get("risk_level", "medium") if isinstance(risk, dict)
                        else getattr(risk, 'risk_level', 'medium')
                    )
                    if llm_risk_level not in ("high", "medium", "low"):
                        llm_risk_level = "medium"

                    rf_obj = RedFlag(
                        clause_text=clause,
                        title=f"Risk in {section.replace('_', ' ').title()}",
                        risk_level=llm_risk_level,
                        why_flag=reason,
                        risks=reason,
                        plain_explanation=reason,
                        suggestion="Review this section carefully"
                    )
                    red_flags_objs.append(rf_obj)
                    red_flags_raw.append(rf_obj.model_dump())
            
            # Calculate Deterministic Fairness Score
            fairness_score, fairness_explanation = ScoringEngine.calculate_score(
                sla=sla_data,
                risks=red_flags_objs,
                contract_type=data.get("contract_type", "lease") 
            )
            
            return ContractAnalysisResult(
                sla_data=sla_data,
                fairness_score=fairness_score,
                fairness_explanation=fairness_explanation,
                red_flags=red_flags_raw,
                confidence_score=data.get("confidence_score", 50),
                contract_type=data.get("contract_type", "lease"),
                detailed_analysis=detailed
            )
            
        except json.JSONDecodeError as e:
            raise LLMException(f"Failed to parse LLM response as JSON: {str(e)}")
    
    async def generate_negotiation_response(
        self, 
        user_message: str, 
        context: Optional[Dict[str, Any]] = None,
        conversation_history: Optional[list] = None
    ) -> Dict[str, Any]:
        """
        Generate a response for the negotiation chatbot
        
        Args:
            user_message: The user's question or message
            context: Optional context (contract data, vehicle info)
            conversation_history: Previous messages in the conversation
            
        Returns:
            Dict with response and suggested actions
        """
        self._ensure_model()
        
        prompt = self._build_negotiation_prompt(user_message, context, conversation_history)
        
        try:
            response = self.model.generate_content(prompt)
            return self._parse_negotiation_response(response.text)
        except Exception as e:
            raise LLMException(f"Negotiation response failed: {str(e)}")
    
    def _build_negotiation_prompt(
        self, 
        user_message: str, 
        context: Optional[Dict[str, Any]] = None,
        history: Optional[list] = None
    ) -> str:
        """Build prompt for negotiation assistant"""
        
        context_str = ""
        if context:
            context_str = f"""
CONTEXT (Contract/Vehicle Information):
{json.dumps(context, indent=2)}
"""
        
        history_str = ""
        if history:
            history_str = "\nCONVERSATION HISTORY:\n"
            for msg in history[-10:]:  # Last 10 messages
                role = msg.get("role", "user").upper()
                content = msg.get("content", "")
                history_str += f"{role}: {content}\n"
        
        prompt = f"""You are an expert automotive negotiation advisor helping a consumer get the best deal on their car lease or loan.

{context_str}
{history_str}

USER'S QUESTION/MESSAGE:
{user_message}

Provide helpful, actionable advice. Consider:
1. Fair market values and typical negotiation points
2. Red flags or concerns from the contract (if provided)
3. Specific negotiation strategies and talking points
4. Questions the user should ask the dealer/lender

Respond in JSON format:
{{
    "response": "<your detailed response to the user>",
    "suggested_actions": ["<list of specific actions they can take>"],
    "negotiation_points": ["<key points to negotiate>"],
    "questions_for_dealer": ["<questions to ask the dealer/lender>"]
}}

Be supportive but realistic. Help them negotiate effectively."""

        return prompt
    
    def _parse_negotiation_response(self, response_text: str) -> Dict[str, Any]:
        """Parse negotiation response"""
        try:
            clean_text = response_text.strip()
            if clean_text.startswith("```"):
                clean_text = re.sub(r'^```\w*\n?', '', clean_text)
                clean_text = re.sub(r'\n?```$', '', clean_text)
            
            return json.loads(clean_text)
        except json.JSONDecodeError:
            # Fallback if JSON parsing fails
            return {
                "response": response_text,
                "suggested_actions": [],
                "negotiation_points": [],
                "questions_for_dealer": []
            }
    
    async def generate_negotiation_email(
        self,
        contract_data: Dict[str, Any],
        email_type: str,
        specific_points: Optional[list] = None,
        tone: str = "professional"
    ) -> Dict[str, str]:
        """
        Generate a negotiation email
        
        Args:
            contract_data: The contract analysis data
            email_type: Type of email (initial_offer, counter_offer, question, final_offer)
            specific_points: Specific points to address
            tone: Email tone (professional, firm, friendly)
            
        Returns:
            Dict with subject and body
        """
        self._ensure_model()
        
        points_str = ""
        if specific_points:
            points_str = f"\nSpecific points to address:\n" + "\n".join(f"- {p}" for p in specific_points)
        
        prompt = f"""Generate a {tone} {email_type.replace('_', ' ')} email for car lease/loan negotiation.

CONTRACT INFORMATION:
{json.dumps(contract_data, indent=2)}
{points_str}

EMAIL TYPE: {email_type}
TONE: {tone}

Generate a professional email that:
1. Is polite but assertive
2. References specific contract terms
3. Proposes reasonable alternatives
4. Maintains leverage while being respectful

Respond in JSON format:
{{
    "subject": "<email subject line>",
    "body": "<full email body>",
    "key_points": ["<main negotiation points in the email>"]
}}"""

        try:
            response = self.model.generate_content(prompt)
            clean_text = response.text.strip()
            if clean_text.startswith("```"):
                clean_text = re.sub(r'^```\w*\n?', '', clean_text)
                clean_text = re.sub(r'\n?```$', '', clean_text)
            
            return json.loads(clean_text)
        except Exception as e:
            raise LLMException(f"Email generation failed: {str(e)}")

    async def generate_negotiation_strategy(
        self,
        sla_data: Dict[str, Any],
        risk_assessment: Optional[Dict[str, Any]] = None,
        market_data: Optional[Dict[str, Any]] = None,
        contract_type: str = "lease"
    ) -> Dict[str, Any]:
        """
        Generate a structured negotiation strategy based on contract SLA,
        risk assessment, and market pricing data (Gap 13).

        Returns dict matching NegotiationStrategyResponse schema.
        """
        self._ensure_model()

        context_parts = [f"CONTRACT TYPE: {contract_type}"]

        context_parts.append(f"\nCONTRACT SLA TERMS:\n{json.dumps(sla_data, indent=2)}")

        if risk_assessment:
            context_parts.append(f"\nRISK ASSESSMENT:\n{json.dumps(risk_assessment, indent=2)}")

        if market_data:
            context_parts.append(f"\nMARKET DATA:\n{json.dumps(market_data, indent=2)}")

        context_str = "\n".join(context_parts)

        prompt = f"""You are an expert automotive negotiation strategist helping a consumer get the best deal.

{context_str}

Based on the contract terms, risk assessment, and market data above, generate a comprehensive negotiation strategy.

Respond in JSON format:
{{
    "priority_actions": [
        "Most important action to take first",
        "Second most important action",
        "..."
    ],
    "counter_offer_points": [
        {{
            "term": "APR",
            "current_value": "current value from contract",
            "suggested_value": "what to counter-offer",
            "justification": "why this counter is reasonable",
            "savings_estimate": "estimated savings in dollars"
        }}
    ],
    "talking_points": [
        "Key point to bring up during negotiation",
        "..."
    ],
    "what_if_scenarios": [
        {{
            "scenario": "Description of the scenario",
            "outcome": "Expected outcome",
            "recommendation": "What to do in this case"
        }}
    ],
    "overall_strategy": "Summary of the recommended negotiation approach"
}}

Be specific, data-driven, and reference actual numbers from the contract. Focus on realistic, achievable improvements."""

        try:
            response = self.model.generate_content(prompt)
            clean_text = response.text.strip()
            if clean_text.startswith("```"):
                clean_text = re.sub(r'^```\w*\n?', '', clean_text)
                clean_text = re.sub(r'\n?```$', '', clean_text)

            result = json.loads(clean_text)
            # Ensure all expected keys exist
            return {
                "priority_actions": result.get("priority_actions", []),
                "counter_offer_points": result.get("counter_offer_points", []),
                "talking_points": result.get("talking_points", []),
                "what_if_scenarios": result.get("what_if_scenarios", []),
                "overall_strategy": result.get("overall_strategy", "Review the contract terms carefully before signing.")
            }
        except Exception as e:
            raise LLMException(f"Strategy generation failed: {str(e)}")


class LLMException(Exception):
    """Custom exception for LLM errors"""
    pass


# Singleton instance
llm_service = LLMService()
