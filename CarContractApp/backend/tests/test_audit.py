"""
Tests for Audit Service (Gap 9)
Verifies that audit events are correctly logged to the audit_logs table.
"""
import sys
import os
import unittest
from datetime import datetime

# Add parent directory to path
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from app.database import Base, AuditLog
from app.services.audit_service import log_event, AuditAction


class TestAuditService(unittest.TestCase):

    @classmethod
    def setUpClass(cls):
        """Create an in-memory SQLite database for testing"""
        cls.engine = create_engine("sqlite:///:memory:")
        Base.metadata.create_all(bind=cls.engine)
        cls.SessionLocal = sessionmaker(bind=cls.engine)

    def setUp(self):
        self.db = self.SessionLocal()

    def tearDown(self):
        self.db.rollback()
        self.db.close()

    def test_log_event_creates_record(self):
        """Verify log_event inserts a record into audit_logs"""
        result = log_event(
            db=self.db,
            user_id=1,
            action=AuditAction.CONTRACT_UPLOADED,
            entity_type="contract",
            entity_id=42,
        )
        self.db.commit()

        self.assertIsNotNone(result)
        self.assertEqual(result.user_id, 1)
        self.assertEqual(result.action, "contract.uploaded")
        self.assertEqual(result.entity_type, "contract")
        self.assertEqual(result.entity_id, 42)

    def test_log_event_with_details(self):
        """Verify JSON details are stored correctly"""
        details = {"filename": "contract.pdf", "file_size": 1024}
        result = log_event(
            db=self.db,
            user_id=2,
            action=AuditAction.CONTRACT_ANALYZED,
            entity_type="contract",
            entity_id=7,
            details=details,
            ip_address="192.168.1.1"
        )
        self.db.commit()

        self.assertIsNotNone(result)
        self.assertEqual(result.details, details)
        self.assertEqual(result.ip_address, "192.168.1.1")

    def test_log_event_with_null_user(self):
        """System events should work without a user_id"""
        result = log_event(
            db=self.db,
            user_id=None,
            action="system.startup",
            entity_type=None,
            entity_id=None,
        )
        self.db.commit()

        self.assertIsNotNone(result)
        self.assertIsNone(result.user_id)

    def test_log_event_records_timestamp(self):
        """Verify created_at is set"""
        result = log_event(
            db=self.db,
            user_id=1,
            action=AuditAction.CONTRACT_DELETED,
            entity_type="contract",
            entity_id=1,
        )
        self.db.commit()

        self.assertIsNotNone(result.created_at)
        self.assertIsInstance(result.created_at, datetime)

    def test_multiple_events_for_same_entity(self):
        """Multiple events for the same entity should all be recorded"""
        log_event(self.db, 1, AuditAction.CONTRACT_UPLOADED, "contract", 10)
        log_event(self.db, 1, AuditAction.LLM_ANALYSIS_STARTED, "contract", 10)
        log_event(self.db, 1, AuditAction.CONTRACT_ANALYZED, "contract", 10)
        self.db.commit()

        events = self.db.query(AuditLog).filter(
            AuditLog.entity_type == "contract",
            AuditLog.entity_id == 10
        ).all()

        self.assertEqual(len(events), 3)

    def test_action_constants(self):
        """Verify action constants are properly defined strings"""
        self.assertEqual(AuditAction.CONTRACT_UPLOADED, "contract.uploaded")
        self.assertEqual(AuditAction.CONTRACT_ANALYZED, "contract.analyzed")
        self.assertEqual(AuditAction.CONTRACT_DELETED, "contract.deleted")
        self.assertEqual(AuditAction.LLM_ANALYSIS_STARTED, "llm.analysis_started")
        self.assertEqual(AuditAction.CONTRACT_STATUS_CHANGED, "contract.status_changed")


if __name__ == '__main__':
    unittest.main()
