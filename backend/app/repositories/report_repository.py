from typing import Optional, List
from sqlalchemy.orm import Session

from app.models.models import Report


class ReportRepository:
    def __init__(self, db: Session):
        self.db = db

    def get_by_id(self, report_id: str) -> Optional[Report]:
        return self.db.query(Report).filter(Report.id == report_id).first()

    def list_all(self, status: Optional[str] = None, skip: int = 0, limit: int = 100) -> List[Report]:
        q = self.db.query(Report)
        if status:
            q = q.filter(Report.status == status)
        return q.order_by(Report.created_at.desc()).offset(skip).limit(limit).all()

    def list_by_user(self, user_id: str) -> List[Report]:
        return (
            self.db.query(Report)
            .filter(Report.user_id == user_id)
            .order_by(Report.created_at.desc())
            .all()
        )

    def count(self, status: Optional[str] = None) -> int:
        q = self.db.query(Report)
        if status:
            q = q.filter(Report.status == status)
        return q.count()

    def create(self, **kwargs) -> Report:
        report = Report(**kwargs)
        self.db.add(report)
        self.db.commit()
        self.db.refresh(report)
        return report

    def update(self, report: Report, **kwargs) -> Report:
        for key, value in kwargs.items():
            if value is not None:
                setattr(report, key, value)
        self.db.commit()
        self.db.refresh(report)
        return report
