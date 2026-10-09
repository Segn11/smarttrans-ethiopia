from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.repositories.route_repository import RouteRepository
from app.services.route_service import RouteSearchService
from app.schemas import RouteResponse

router = APIRouter(prefix="/routes", tags=["Routes"])


@router.get("")
def list_routes(
    city_id: Optional[str] = None,
    status: Optional[str] = "active",
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=200),
    db: Session = Depends(get_db),
):
    repo = RouteRepository(db)
    routes = repo.list_all(city_id=city_id, status=status, skip=skip, limit=limit)
    total = repo.count(city_id=city_id, status=status)
    return {
        "success": True,
        "total": total,
        "data": [RouteResponse.model_validate(r) for r in routes],
    }


@router.get("/search")
def search_routes(
    from_station: str = Query(..., alias="from"),
    to_station: str = Query(..., alias="to"),
    sort_by: str = Query("fastest", enum=["fastest", "cheapest", "fewest_transfers"]),
    db: Session = Depends(get_db),
):
    svc = RouteSearchService(db)
    results = svc.search(from_station, to_station, sort_by=sort_by)
    if not results:
        return {
            "success": False,
            "message": "No route found between the selected locations.",
            "data": [],
        }
    return {"success": True, "data": results}


@router.get("/{route_id}")
def get_route(route_id: str, db: Session = Depends(get_db)):
    repo = RouteRepository(db)
    route = repo.get_by_id(route_id)
    if not route:
        raise HTTPException(status_code=404, detail="Route not found")
    return {"success": True, "data": RouteResponse.model_validate(route)}
