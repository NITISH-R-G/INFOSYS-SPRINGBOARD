"""Initial schema — all tables

Revision ID: 001
Revises: None
Create Date: 2026-02-22
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = "001"
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # --- users ---
    op.create_table(
        "users",
        sa.Column("id", sa.Integer(), primary_key=True, autoincrement=True),
        sa.Column("email", sa.String(255), unique=True, nullable=False, index=True),
        sa.Column("full_name", sa.String(255)),
        sa.Column("hashed_password", sa.String(255), nullable=False),
        sa.Column("role", sa.String(50), server_default="buyer"),
        sa.Column("phone_number", sa.String(20), nullable=True),
        sa.Column("profile_image_url", sa.String(500), nullable=True),
        sa.Column("is_active", sa.Boolean(), server_default=sa.text("true")),
        sa.Column("created_at", sa.DateTime(), server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(), server_default=sa.func.now()),
    )

    # --- vehicles ---
    op.create_table(
        "vehicles",
        sa.Column("id", sa.Integer(), primary_key=True, autoincrement=True),
        sa.Column("vin", sa.String(17), unique=True, index=True),
        sa.Column("make", sa.String(100)),
        sa.Column("model", sa.String(100)),
        sa.Column("year", sa.Integer()),
        sa.Column("trim", sa.String(100)),
        sa.Column("body_type", sa.String(100)),
        sa.Column("engine", sa.String(200)),
        sa.Column("transmission", sa.String(100)),
        sa.Column("drivetrain", sa.String(50)),
        sa.Column("fuel_type", sa.String(50)),
        sa.Column("estimated_value", sa.Float()),
        sa.Column("mileage", sa.Integer()),
        sa.Column("recalls", sa.JSON()),
        sa.Column("source", sa.String(50), server_default="NHTSA"),
        sa.Column("fetched_at", sa.DateTime(), server_default=sa.func.now()),
    )

    # --- dealers ---
    op.create_table(
        "dealers",
        sa.Column("id", sa.Integer(), primary_key=True, autoincrement=True),
        sa.Column("name", sa.String(255), nullable=False),
        sa.Column("address", sa.Text()),
        sa.Column("phone", sa.String(20)),
        sa.Column("email", sa.String(255)),
        sa.Column("website", sa.String(255)),
        sa.Column("rating", sa.Float()),
    )

    # --- lenders ---
    op.create_table(
        "lenders",
        sa.Column("id", sa.Integer(), primary_key=True, autoincrement=True),
        sa.Column("name", sa.String(255), nullable=False),
        sa.Column("type", sa.String(50)),
        sa.Column("address", sa.Text()),
        sa.Column("phone", sa.String(20)),
        sa.Column("website", sa.String(255)),
    )

    # --- contracts ---
    op.create_table(
        "contracts",
        sa.Column("id", sa.Integer(), primary_key=True, autoincrement=True),
        sa.Column("user_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("vehicle_id", sa.Integer(), sa.ForeignKey("vehicles.id"), nullable=True),
        sa.Column("dealer_id", sa.Integer(), sa.ForeignKey("dealers.id"), nullable=True),
        sa.Column("lender_id", sa.Integer(), sa.ForeignKey("lenders.id"), nullable=True),
        sa.Column("contract_type", sa.String(20)),
        sa.Column("job_id", sa.String(100), index=True, nullable=True),
        sa.Column("status", sa.String(20), server_default="pending"),
        sa.Column("error_message", sa.Text(), nullable=True),
        sa.Column("raw_text", sa.Text(), nullable=True),
        sa.Column("fairness_score", sa.Integer(), nullable=True),
        sa.Column("fairness_explanation", sa.Text(), nullable=True),
        sa.Column("confidence_score", sa.Integer(), nullable=True),
        sa.Column("detailed_analysis", sa.JSON(), nullable=True),
        sa.Column("red_flags", sa.JSON(), nullable=True),
        sa.Column("created_at", sa.DateTime(), server_default=sa.func.now()),
        sa.Column("analyzed_at", sa.DateTime(), nullable=True),
    )

    # --- contract_files ---
    op.create_table(
        "contract_files",
        sa.Column("id", sa.Integer(), primary_key=True, autoincrement=True),
        sa.Column("contract_id", sa.Integer(), sa.ForeignKey("contracts.id", ondelete="CASCADE"), nullable=False),
        sa.Column("filename", sa.String(255), nullable=False),
        sa.Column("file_path", sa.String(500), nullable=False),
        sa.Column("file_type", sa.String(20)),
        sa.Column("page_count", sa.Integer(), nullable=True),
        sa.Column("file_size_bytes", sa.Integer(), nullable=True),
        sa.Column("uploaded_at", sa.DateTime(), server_default=sa.func.now()),
    )

    # --- contract_pages ---
    op.create_table(
        "contract_pages",
        sa.Column("id", sa.Integer(), primary_key=True, autoincrement=True),
        sa.Column("contract_file_id", sa.Integer(), sa.ForeignKey("contract_files.id", ondelete="CASCADE"), nullable=False),
        sa.Column("page_number", sa.Integer(), nullable=False),
        sa.Column("raw_text", sa.Text(), nullable=True),
        sa.Column("ocr_confidence", sa.Float(), nullable=True),
        sa.Column("processing_time_ms", sa.Integer(), nullable=True),
    )

    # --- contract_sla ---
    op.create_table(
        "contract_sla",
        sa.Column("id", sa.Integer(), primary_key=True, autoincrement=True),
        sa.Column("contract_id", sa.Integer(), sa.ForeignKey("contracts.id", ondelete="CASCADE"), nullable=False, unique=True),
        sa.Column("currency_code", sa.String(3), server_default="USD"),
        sa.Column("apr", sa.Float(), nullable=True),
        sa.Column("term_months", sa.Integer(), nullable=True),
        sa.Column("monthly_payment", sa.Float(), nullable=True),
        sa.Column("down_payment", sa.Float(), nullable=True),
        sa.Column("residual_value", sa.Float(), nullable=True),
        sa.Column("buyout_price", sa.Float(), nullable=True),
        sa.Column("documentation_fee", sa.Float(), nullable=True),
        sa.Column("acquisition_fee", sa.Float(), nullable=True),
        sa.Column("disposition_fee", sa.Float(), nullable=True),
        sa.Column("mileage_limit", sa.Integer(), nullable=True),
        sa.Column("mileage_overage_fee", sa.Float(), nullable=True),
        sa.Column("early_termination_fee", sa.String(255), nullable=True),
        sa.Column("maintenance_included", sa.Boolean(), nullable=True),
        sa.Column("warranty_months", sa.Integer(), nullable=True),
        sa.Column("market_value", sa.Float(), nullable=True),
        sa.Column("market_value_high", sa.Float(), nullable=True),
        sa.Column("market_value_low", sa.Float(), nullable=True),
        sa.Column("market_confidence", sa.String(20), nullable=True),
        sa.Column("fairness_score", sa.Integer(), nullable=True),
        sa.Column("fairness_explanation", sa.Text(), nullable=True),
        sa.Column("created_at", sa.DateTime(), server_default=sa.func.now()),
    )

    # --- extracted_clauses ---
    op.create_table(
        "extracted_clauses",
        sa.Column("id", sa.Integer(), primary_key=True, autoincrement=True),
        sa.Column("contract_id", sa.Integer(), sa.ForeignKey("contracts.id", ondelete="CASCADE"), nullable=False),
        sa.Column("section_key", sa.String(100), nullable=False),
        sa.Column("section_title", sa.String(255), nullable=True),
        sa.Column("clause_text", sa.Text(), nullable=False),
        sa.Column("risk_level", sa.String(10), nullable=True),
        sa.Column("risk_reason", sa.Text(), nullable=True),
        sa.Column("suggestion", sa.Text(), nullable=True),
        sa.Column("source_page", sa.Integer(), nullable=True),
        sa.Column("coordinates", sa.JSON(), nullable=True),
        sa.Column("created_at", sa.DateTime(), server_default=sa.func.now()),
    )

    # --- negotiations ---
    op.create_table(
        "negotiations",
        sa.Column("id", sa.Integer(), primary_key=True, autoincrement=True),
        sa.Column("user_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("contract_id", sa.Integer(), sa.ForeignKey("contracts.id"), nullable=True),
        sa.Column("session_id", sa.String(50), index=True),
        sa.Column("messages", sa.JSON()),
        sa.Column("generated_emails", sa.JSON()),
        sa.Column("negotiation_points", sa.JSON()),
        sa.Column("created_at", sa.DateTime(), server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(), server_default=sa.func.now()),
    )

    # --- conversations ---
    op.create_table(
        "conversations",
        sa.Column("id", sa.Integer(), primary_key=True, autoincrement=True),
        sa.Column("buyer_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("dealer_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("contract_id", sa.Integer(), sa.ForeignKey("contracts.id"), nullable=True),
        sa.Column("subject", sa.String(255), nullable=True),
        sa.Column("created_at", sa.DateTime(), server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(), server_default=sa.func.now()),
    )

    # --- messages ---
    op.create_table(
        "messages",
        sa.Column("id", sa.Integer(), primary_key=True, autoincrement=True),
        sa.Column("conversation_id", sa.Integer(), sa.ForeignKey("conversations.id"), nullable=False),
        sa.Column("sender_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("content", sa.Text(), nullable=False),
        sa.Column("is_read", sa.Boolean(), server_default=sa.text("false")),
        sa.Column("created_at", sa.DateTime(), server_default=sa.func.now()),
    )

    # --- audit_logs ---
    op.create_table(
        "audit_logs",
        sa.Column("id", sa.Integer(), primary_key=True, autoincrement=True),
        sa.Column("user_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=True),
        sa.Column("action", sa.String(100), nullable=False),
        sa.Column("entity_type", sa.String(50)),
        sa.Column("entity_id", sa.Integer()),
        sa.Column("details", sa.JSON()),
        sa.Column("ip_address", sa.String(45)),
        sa.Column("created_at", sa.DateTime(), server_default=sa.func.now()),
    )


def downgrade() -> None:
    op.drop_table("audit_logs")
    op.drop_table("messages")
    op.drop_table("conversations")
    op.drop_table("negotiations")
    op.drop_table("extracted_clauses")
    op.drop_table("contract_sla")
    op.drop_table("contract_pages")
    op.drop_table("contract_files")
    op.drop_table("contracts")
    op.drop_table("lenders")
    op.drop_table("dealers")
    op.drop_table("vehicles")
    op.drop_table("users")
