"""
WebSocket Router for Real-time Task Status Updates
Allows the frontend to subscribe to Celery task progress.
"""
import asyncio
import json
import logging
from fastapi import APIRouter, WebSocket, WebSocketDisconnect

logger = logging.getLogger(__name__)

router = APIRouter(tags=["WebSocket"])


@router.websocket("/ws/tasks/{job_id}")
async def task_status_websocket(websocket: WebSocket, job_id: str):
    """
    WebSocket endpoint that streams Celery task status updates.
    
    The client connects to ws://host/ws/tasks/{job_id} and receives
    JSON messages with the task state, stage name, message, and progress %.
    
    Message format:
    {
        "state": "SCANNING",
        "stage": "scanning",
        "message": "Scanning document...",
        "progress": 10
    }
    """
    await websocket.accept()
    logger.info(f"WebSocket connected for task: {job_id}")

    try:
        from .celery_app import celery_app

        previous_state = None

        while True:
            # Poll Celery task result
            result = celery_app.AsyncResult(job_id)

            current_state = result.state
            meta = result.info if isinstance(result.info, dict) else {}

            payload = {
                "state": current_state,
                "stage": meta.get("stage", "unknown"),
                "message": meta.get("message", f"Status: {current_state}"),
                "progress": meta.get("progress", 0),
            }

            # Only send if state changed or we have new info
            if current_state != previous_state or current_state in ("SCANNING", "EXTRACTING", "ANALYZING"):
                await websocket.send_json(payload)
                previous_state = current_state

            # Terminal states
            if current_state in ("SUCCESS", "FAILURE", "REVOKED"):
                # Send final payload with result data
                if current_state == "SUCCESS":
                    payload["contract_id"] = meta.get("contract_id")
                    payload["fairness_score"] = meta.get("fairness_score")
                    await websocket.send_json(payload)

                break

            await asyncio.sleep(1)  # Poll every second

    except WebSocketDisconnect:
        logger.info(f"WebSocket disconnected for task: {job_id}")
    except Exception as e:
        logger.error(f"WebSocket error for task {job_id}: {e}")
        try:
            await websocket.send_json({
                "state": "ERROR",
                "stage": "error",
                "message": "Connection error. Please refresh.",
                "progress": 0
            })
        except Exception:
            pass
    finally:
        try:
            await websocket.close()
        except Exception:
            pass
