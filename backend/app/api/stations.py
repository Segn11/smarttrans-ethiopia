from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.security import get_current_user
from app.repositories.station_repository import StationRepository
from app.schemas import StationResponse, NearbyStationResponse

router = APIRouter(prefix="/stations", tags=["Stations"])


@router.get("")
def list_stations(
    city_id: Optional[str] = None,
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=200),
    db: Session = Depends(get_db),
):
    repo = StationRepository(db)
    stations = repo.list_all(city_id=city_id, skip=skip, limit=limit)
    total = repo.count(city_id=city_id)
    return {
        "success": True,
        "total": total,
        "data": [StationResponse.model_validate(s) for s in stations],
    }


@router.get("/nearby")
def get_nearby_stations(
    latitude: float = Query(...),
    longitude: float = Query(...),
    radius: float = Query(2000, description="Radius in meters"),
    db: Session = Depends(get_db),
):
    repo = StationRepository(db)
    nearby = repo.get_nearby(latitude, longitude, radius)
    return {
        "success": True,
        "data": [
            {
                "station": StationResponse.model_validate(s),
                "distance_meters": round(dist, 1),
            }
            for s, dist in nearby
        ],
    }


@router.get("/{station_id}")
def get_station(station_id: str, db: Session = Depends(get_db)):
    repo = StationRepository(db)
    station = repo.get_by_id(station_id)
    if not station:
        raise HTTPException(status_code=404, detail="Station not found")
    return {"success": True, "data": StationResponse.model_validate(station)}
