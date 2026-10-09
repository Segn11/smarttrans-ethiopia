from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.security import get_current_user
from app.repositories.report_repository import ReportRepository
from app.schemas import ReportCreate, ReportResponse

router = APIRouter(prefix="/reports", tags=["Reports"])

VALID_TYPES = {"route_unavailable", "station_closed", "fare_changed", "heavy_traffic", "incorrect_info", "other"}


@router.post("", status_code=status.HTTP_201_CREATED)
def submit_report(
    payload: ReportCreate,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    if payload.report_type not in VALID_TYPES:
        raise HTTPException(status_code=422, detail=f"Invalid report_type. Must be one of: {', '.join(VALID_TYPES)}")
    repo = ReportRepository(db)
    report = repo.create(
        user_id=current_user.id,
        route_id=payload.route_id,
        report_type=payload.report_type,
        description=payload.description,
    )
    return {"success": True, "data": ReportResponse.model_validate(report)}


@router.get("/my")
def my_reports(current_user=Depends(get_current_user), db: Session = Depends(get_db)):
    repo = ReportRepository(db)
    reports = repo.list_by_user(current_user.id)
    return {"success": True, "data": [ReportResponse.model_validate(r) for r in reports]}
