from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy import text
from ..database import get_db

router = APIRouter(prefix="/health", tags=["health"])

@router.get("/")
def health_check():
    """Basic health check endpoint."""
    return {
        "status": "healthy",
        "service": "user-service",
        "version": "1.0.0"
    }

@router.get("/ready")
def readiness_check(db: Session = Depends(get_db)):
    """Readiness check - verifies database connectivity."""
    try:
        db.execute(text("SELECT 1"))
        return {
            "status": "ready",
            "service": "user-service",
            "database": "connected"
        }
    except Exception as e:
        return {
            "status": "not_ready",
            "service": "user-service",
            "database": "disconnected",
            "error": str(e)
        }, 503
