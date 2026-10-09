"""
Admin API — all endpoints require admin role.
"""
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.security import require_admin
from app.repositories.user_repository import UserRepository
from app.repositories.station_repository import StationRepository
from app.repositories.route_repository import RouteRepository, FareRepository
from app.repositories.report_repository import ReportRepository
from app.repositories.notification_repository import NotificationRepository
from app.repositories.city_repository import CityRepository, TransportTypeRepository
from app.schemas import (
    StationCreate, StationUpdate, StationResponse,
    RouteCreate, RouteUpdate, RouteResponse,
    RouteStopCreate, RouteStopResponse,
    FareCreate, FareUpdate, FareResponse,
    ReportStatusUpdate, ReportResponse,
    NotificationCreate, NotificationResponse,
    CityCreate, CityUpdate, CityResponse,
    TransportTypeCreate, TransportTypeResponse,
    DashboardStats,
)

router = APIRouter(prefix="/admin", tags=["Admin"])


# ─────────────────────────────────────────────────────────
# Dashboard
# ─────────────────────────────────────────────────────────

@router.get("/dashboard")
def dashboard(db: Session = Depends(get_db), admin=Depends(require_admin)):
    users = UserRepository(db).count()
    stations = StationRepository(db).count()
    routes_repo = RouteRepository(db)
    total_routes = routes_repo.count()
    active_routes = routes_repo.count(status="active")
    report_repo = ReportRepository(db)
    total_reports = report_repo.count()
    pending_reports = report_repo.count(status="pending")
    return {
        "success": True,
        "data": DashboardStats(
            total_users=users,
            total_stations=stations,
            total_routes=total_routes,
            total_reports=total_reports,
            active_routes=active_routes,
            pending_reports=pending_reports,
        ),
    }


# ─────────────────────────────────────────────────────────
# Cities
# ─────────────────────────────────────────────────────────

@router.get("/cities")
def list_cities(db: Session = Depends(get_db), admin=Depends(require_admin)):
    repo = CityRepository(db)
    cities = repo.list_all()
    return {"success": True, "data": [CityResponse.model_validate(c) for c in cities]}


@router.post("/cities", status_code=201)
def create_city(payload: CityCreate, db: Session = Depends(get_db), admin=Depends(require_admin)):
    repo = CityRepository(db)
    city = repo.create(**payload.model_dump())
    return {"success": True, "data": CityResponse.model_validate(city)}


@router.put("/cities/{city_id}")
def update_city(city_id: str, payload: CityUpdate, db: Session = Depends(get_db), admin=Depends(require_admin)):
    repo = CityRepository(db)
    city = repo.get_by_id(city_id)
    if not city:
        raise HTTPException(status_code=404, detail="City not found")
    city = repo.update(city, **payload.model_dump(exclude_unset=True))
    return {"success": True, "data": CityResponse.model_validate(city)}


# ─────────────────────────────────────────────────────────
# Transport Types
# ─────────────────────────────────────────────────────────

@router.get("/transport-types")
def list_transport_types(db: Session = Depends(get_db), admin=Depends(require_admin)):
    repo = TransportTypeRepository(db)
    tts = repo.list_all()
    return {"success": True, "data": [TransportTypeResponse.model_validate(t) for t in tts]}


@router.post("/transport-types", status_code=201)
def create_transport_type(payload: TransportTypeCreate, db: Session = Depends(get_db), admin=Depends(require_admin)):
    repo = TransportTypeRepository(db)
    tt = repo.create(**payload.model_dump())
    return {"success": True, "data": TransportTypeResponse.model_validate(tt)}


# ─────────────────────────────────────────────────────────
# Stations
# ─────────────────────────────────────────────────────────

@router.get("/stations")
def list_stations(
    city_id: Optional[str] = None,
    skip: int = 0, limit: int = 100,
    db: Session = Depends(get_db), admin=Depends(require_admin),
):
    repo = StationRepository(db)
    stations = repo.list_all(city_id=city_id, skip=skip, limit=limit)
    return {"success": True, "data": [StationResponse.model_validate(s) for s in stations]}


@router.post("/stations", status_code=201)
def create_station(payload: StationCreate, db: Session = Depends(get_db), admin=Depends(require_admin)):
    repo = StationRepository(db)
    station = repo.create(**payload.model_dump())
    return {"success": True, "data": StationResponse.model_validate(station)}


@router.get("/stations/{station_id}")
def get_station(station_id: str, db: Session = Depends(get_db), admin=Depends(require_admin)):
    repo = StationRepository(db)
    station = repo.get_by_id(station_id)
    if not station:
        raise HTTPException(status_code=404, detail="Station not found")
    return {"success": True, "data": StationResponse.model_validate(station)}


@router.put("/stations/{station_id}")
def update_station(station_id: str, payload: StationUpdate, db: Session = Depends(get_db), admin=Depends(require_admin)):
    repo = StationRepository(db)
    station = repo.get_by_id(station_id)
    if not station:
        raise HTTPException(status_code=404, detail="Station not found")
    station = repo.update(station, **payload.model_dump(exclude_unset=True))
    return {"success": True, "data": StationResponse.model_validate(station)}


@router.delete("/stations/{station_id}")
def delete_station(station_id: str, db: Session = Depends(get_db), admin=Depends(require_admin)):
    repo = StationRepository(db)
    station = repo.get_by_id(station_id)
    if not station:
        raise HTTPException(status_code=404, detail="Station not found")
    repo.delete(station)
    return {"success": True, "message": "Station deleted"}


# ─────────────────────────────────────────────────────────
# Routes
# ─────────────────────────────────────────────────────────

@router.get("/routes")
def list_routes(
    city_id: Optional[str] = None, status: Optional[str] = None,
    skip: int = 0, limit: int = 100,
    db: Session = Depends(get_db), admin=Depends(require_admin),
):
    repo = RouteRepository(db)
    routes = repo.list_all(city_id=city_id, status=status, skip=skip, limit=limit)
    return {"success": True, "data": [RouteResponse.model_validate(r) for r in routes]}


@router.post("/routes", status_code=201)
def create_route(payload: RouteCreate, db: Session = Depends(get_db), admin=Depends(require_admin)):
    repo = RouteRepository(db)
    route = repo.create(**payload.model_dump())
    return {"success": True, "data": RouteResponse.model_validate(route)}


@router.get("/routes/{route_id}")
def get_route(route_id: str, db: Session = Depends(get_db), admin=Depends(require_admin)):
    repo = RouteRepository(db)
    route = repo.get_by_id(route_id)
    if not route:
        raise HTTPException(status_code=404, detail="Route not found")
    return {"success": True, "data": RouteResponse.model_validate(route)}


@router.put("/routes/{route_id}")
def update_route(route_id: str, payload: RouteUpdate, db: Session = Depends(get_db), admin=Depends(require_admin)):
    repo = RouteRepository(db)
    route = repo.get_by_id(route_id)
    if not route:
        raise HTTPException(status_code=404, detail="Route not found")
    route = repo.update(route, **payload.model_dump(exclude_unset=True))
    return {"success": True, "data": RouteResponse.model_validate(route)}


@router.delete("/routes/{route_id}")
def delete_route(route_id: str, db: Session = Depends(get_db), admin=Depends(require_admin)):
    repo = RouteRepository(db)
    route = repo.get_by_id(route_id)
    if not route:
        raise HTTPException(status_code=404, detail="Route not found")
    repo.delete(route)
    return {"success": True, "message": "Route deleted"}


# ─────────────────────────────────────────────────────────
# Route Stops
# ─────────────────────────────────────────────────────────

@router.get("/routes/{route_id}/stops")
def get_route_stops(route_id: str, db: Session = Depends(get_db), admin=Depends(require_admin)):
    repo = RouteRepository(db)
    stops = repo.get_stops(route_id)
    return {"success": True, "data": [RouteStopResponse.model_validate(s) for s in stops]}


@router.post("/routes/{route_id}/stops", status_code=201)
def add_stop(route_id: str, payload: RouteStopCreate, db: Session = Depends(get_db), admin=Depends(require_admin)):
    repo = RouteRepository(db)
    stop = repo.add_stop(route_id=route_id, station_id=payload.station_id, stop_order=payload.stop_order)
    return {"success": True, "data": RouteStopResponse.model_validate(stop)}


@router.delete("/stops/{stop_id}")
def remove_stop(stop_id: str, db: Session = Depends(get_db), admin=Depends(require_admin)):
    repo = RouteRepository(db)
    repo.remove_stop(stop_id)
    return {"success": True, "message": "Stop removed"}


# ─────────────────────────────────────────────────────────
# Fares
# ─────────────────────────────────────────────────────────

@router.get("/fares")
def list_fares(
    route_id: Optional[str] = None, skip: int = 0, limit: int = 100,
    db: Session = Depends(get_db), admin=Depends(require_admin),
):
    repo = FareRepository(db)
    fares = repo.list_all(route_id=route_id, skip=skip, limit=limit)
    return {"success": True, "data": [FareResponse.model_validate(f) for f in fares]}


@router.post("/fares", status_code=201)
def create_fare(payload: FareCreate, db: Session = Depends(get_db), admin=Depends(require_admin)):
    repo = FareRepository(db)
    fare = repo.create(**payload.model_dump())
    return {"success": True, "data": FareResponse.model_validate(fare)}


@router.put("/fares/{fare_id}")
def update_fare(fare_id: str, payload: FareUpdate, db: Session = Depends(get_db), admin=Depends(require_admin)):
    repo = FareRepository(db)
    fare = repo.get_by_id(fare_id)
    if not fare:
        raise HTTPException(status_code=404, detail="Fare not found")
    fare = repo.update(fare, **payload.model_dump(exclude_unset=True))
    return {"success": True, "data": FareResponse.model_validate(fare)}


@router.delete("/fares/{fare_id}")
def delete_fare(fare_id: str, db: Session = Depends(get_db), admin=Depends(require_admin)):
    repo = FareRepository(db)
    fare = repo.get_by_id(fare_id)
    if not fare:
        raise HTTPException(status_code=404, detail="Fare not found")
    repo.delete(fare)
    return {"success": True, "message": "Fare deleted"}


# ─────────────────────────────────────────────────────────
# Reports
# ─────────────────────────────────────────────────────────

@router.get("/reports")
def list_reports(
    status: Optional[str] = None, skip: int = 0, limit: int = 100,
    db: Session = Depends(get_db), admin=Depends(require_admin),
):
    repo = ReportRepository(db)
    reports = repo.list_all(status=status, skip=skip, limit=limit)
    return {"success": True, "data": [ReportResponse.model_validate(r) for r in reports]}


@router.put("/reports/{report_id}")
def update_report(
    report_id: str, payload: ReportStatusUpdate,
    db: Session = Depends(get_db), admin=Depends(require_admin),
):
    repo = ReportRepository(db)
    report = repo.get_by_id(report_id)
    if not report:
        raise HTTPException(status_code=404, detail="Report not found")
    report = repo.update(report, status=payload.status, admin_notes=payload.admin_notes)
    return {"success": True, "data": ReportResponse.model_validate(report)}


# ─────────────────────────────────────────────────────────
# Notifications
# ─────────────────────────────────────────────────────────

@router.get("/notifications")
def list_notifications(db: Session = Depends(get_db), admin=Depends(require_admin)):
    repo = NotificationRepository(db)
    notifs = repo.list_all()
    return {"success": True, "data": [NotificationResponse.model_validate(n) for n in notifs]}


@router.post("/notifications", status_code=201)
def create_notification(payload: NotificationCreate, db: Session = Depends(get_db), admin=Depends(require_admin)):
    repo = NotificationRepository(db)
    notif = repo.create(**payload.model_dump())
    return {"success": True, "data": NotificationResponse.model_validate(notif)}


@router.delete("/notifications/{notification_id}")
def delete_notification(notification_id: str, db: Session = Depends(get_db), admin=Depends(require_admin)):
    repo = NotificationRepository(db)
    notif = repo.get_by_id(notification_id)
    if not notif:
        raise HTTPException(status_code=404, detail="Notification not found")
    repo.delete(notif)
    return {"success": True, "message": "Notification deleted"}
