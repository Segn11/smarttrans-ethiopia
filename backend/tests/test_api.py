"""
SmartTrans Ethiopia — Backend Tests
"""
import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from app.main import app
from app.core.database import Base, get_db

# Use in-memory SQLite for tests
SQLALCHEMY_TEST_URL = "sqlite:///./test.db"

engine = create_engine(SQLALCHEMY_TEST_URL, connect_args={"check_same_thread": False})
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base.metadata.create_all(bind=engine)


def override_get_db():
    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()


app.dependency_overrides[get_db] = override_get_db

client = TestClient(app)


# ─── Fixtures ────────────────────────────────────────────

@pytest.fixture(scope="function", autouse=True)
def reset_db():
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)
    yield


@pytest.fixture
def registered_user():
    resp = client.post("/api/v1/auth/register", json={
        "name": "Test User",
        "email": "test@example.com",
        "phone": "+251900000001",
        "password": "TestPass@1234",
    })
    assert resp.status_code == 201
    return resp.json()


@pytest.fixture
def auth_headers(registered_user):
    resp = client.post("/api/v1/auth/login", json={
        "email": "test@example.com",
        "password": "TestPass@1234",
    })
    token = resp.json()["data"]["access_token"]
    return {"Authorization": f"Bearer {token}"}


@pytest.fixture
def admin_headers():
    # Register admin directly via DB
    from app.core.security import hash_password
    from app.models.models import User
    db = TestingSessionLocal()
    admin = User(
        name="Admin", email="admin@test.com",
        hashed_password=hash_password("Admin@1234"),
        role="admin",
    )
    db.add(admin)
    db.commit()
    db.close()

    resp = client.post("/api/v1/auth/login", json={
        "email": "admin@test.com",
        "password": "Admin@1234",
    })
    token = resp.json()["data"]["access_token"]
    return {"Authorization": f"Bearer {token}"}


# ─── Health ──────────────────────────────────────────────

def test_health():
    resp = client.get("/")
    assert resp.status_code == 200
    assert resp.json()["success"] is True


# ─── Auth ────────────────────────────────────────────────

def test_register():
    resp = client.post("/api/v1/auth/register", json={
        "name": "Alice",
        "email": "alice@example.com",
        "password": "SecurePass@1",
    })
    assert resp.status_code == 201
    assert resp.json()["success"] is True


def test_register_duplicate_email():
    payload = {"name": "Bob", "email": "bob@example.com", "password": "BobPass@1"}
    client.post("/api/v1/auth/register", json=payload)
    resp = client.post("/api/v1/auth/register", json=payload)
    assert resp.status_code == 409


def test_login(registered_user):
    resp = client.post("/api/v1/auth/login", json={
        "email": "test@example.com",
        "password": "TestPass@1234",
    })
    assert resp.status_code == 200
    assert "access_token" in resp.json()["data"]


def test_login_wrong_password(registered_user):
    resp = client.post("/api/v1/auth/login", json={
        "email": "test@example.com",
        "password": "WrongPassword",
    })
    assert resp.status_code == 401


def test_me(auth_headers):
    resp = client.get("/api/v1/auth/me", headers=auth_headers)
    assert resp.status_code == 200
    assert resp.json()["data"]["email"] == "test@example.com"


def test_me_unauthorized():
    resp = client.get("/api/v1/auth/me")
    assert resp.status_code == 401


# ─── Stations ────────────────────────────────────────────

def test_list_stations_empty():
    resp = client.get("/api/v1/stations")
    assert resp.status_code == 200
    assert resp.json()["data"] == []


def test_admin_create_and_list_station(admin_headers):
    # First create a city
    city_resp = client.post("/api/v1/admin/cities", headers=admin_headers, json={
        "name": "Addis Ababa", "latitude": 9.03, "longitude": 38.74
    })
    city_id = city_resp.json()["data"]["id"]

    resp = client.post("/api/v1/admin/stations", headers=admin_headers, json={
        "name": "Bole", "city_id": city_id, "latitude": 9.01, "longitude": 38.76,
        "operating_hours": "6:00 AM – 9:00 PM",
    })
    assert resp.status_code == 201
    assert resp.json()["data"]["name"] == "Bole"

    list_resp = client.get("/api/v1/stations")
    assert len(list_resp.json()["data"]) == 1


def test_nearby_stations(admin_headers):
    city_resp = client.post("/api/v1/admin/cities", headers=admin_headers, json={
        "name": "Addis Ababa", "latitude": 9.03, "longitude": 38.74
    })
    city_id = city_resp.json()["data"]["id"]
    client.post("/api/v1/admin/stations", headers=admin_headers, json={
        "name": "Mexico", "city_id": city_id, "latitude": 9.0135, "longitude": 38.7612,
    })
    resp = client.get("/api/v1/stations/nearby?latitude=9.0135&longitude=38.7612&radius=100")
    assert resp.status_code == 200
    assert len(resp.json()["data"]) >= 1


# ─── Routes ──────────────────────────────────────────────

def test_admin_create_route(admin_headers):
    city_resp = client.post("/api/v1/admin/cities", headers=admin_headers, json={
        "name": "Addis Ababa"
    })
    city_id = city_resp.json()["data"]["id"]
    tt_resp = client.post("/api/v1/admin/transport-types", headers=admin_headers, json={
        "name": "Minibus", "icon": "🚐",
    })
    tt_id = tt_resp.json()["data"]["id"]
    resp = client.post("/api/v1/admin/routes", headers=admin_headers, json={
        "name": "Bole → Piassa", "city_id": city_id, "transport_type_id": tt_id,
        "estimated_time": 40, "distance": 8.5, "operating_hours": "6:00 AM – 9:00 PM",
    })
    assert resp.status_code == 201
    assert resp.json()["data"]["name"] == "Bole → Piassa"


# ─── Route Search ─────────────────────────────────────────

def test_route_search_no_routes():
    resp = client.get("/api/v1/routes/search?from=station_a&to=station_b")
    assert resp.status_code == 200
    assert resp.json()["success"] is False


# ─── Favorites ────────────────────────────────────────────

def test_favorites_require_auth():
    resp = client.get("/api/v1/favorites")
    assert resp.status_code == 401


def test_add_favorite_invalid_route(auth_headers):
    resp = client.post("/api/v1/favorites", headers=auth_headers, json={
        "route_id": "00000000-0000-0000-0000-000000000000"
    })
    assert resp.status_code == 404


# ─── Reports ─────────────────────────────────────────────

def test_submit_report(auth_headers):
    resp = client.post("/api/v1/reports", headers=auth_headers, json={
        "report_type": "heavy_traffic",
        "description": "Very heavy traffic near Mexico station",
    })
    assert resp.status_code == 201
    assert resp.json()["data"]["report_type"] == "heavy_traffic"


def test_my_reports(auth_headers):
    client.post("/api/v1/reports", headers=auth_headers, json={
        "report_type": "other",
        "description": "Test report",
    })
    resp = client.get("/api/v1/reports/my", headers=auth_headers)
    assert resp.status_code == 200
    assert len(resp.json()["data"]) >= 1


# ─── Admin Authorization ──────────────────────────────────

def test_admin_endpoint_blocked_for_passenger(auth_headers):
    resp = client.get("/api/v1/admin/dashboard", headers=auth_headers)
    assert resp.status_code == 403


def test_admin_dashboard(admin_headers):
    resp = client.get("/api/v1/admin/dashboard", headers=admin_headers)
    assert resp.status_code == 200
    assert "total_users" in resp.json()["data"]


# ─── Notifications ────────────────────────────────────────

def test_notifications_list(auth_headers, admin_headers):
    client.post("/api/v1/admin/notifications", headers=admin_headers, json={
        "title": "Test Notification",
        "message": "This is a test.",
        "notification_type": "info",
    })
    resp = client.get("/api/v1/notifications", headers=auth_headers)
    assert resp.status_code == 200
    assert len(resp.json()["data"]) >= 1
