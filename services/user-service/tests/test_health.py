import pytest
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_health_check():
    """Test basic health check endpoint."""
    response = client.get("/health/")
    assert response.status_code == 200
    assert response.json()["status"] == "healthy"
    assert response.json()["service"] == "user-service"

def test_api_users_list():
    """Test users list endpoint."""
    response = client.get("/api/v1/users")
    assert response.status_code == 200
    assert isinstance(response.json(), list)
