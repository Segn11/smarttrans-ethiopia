from typing import Optional, List
from sqlalchemy.orm import Session

from app.models.models import Notification, NotificationRead


class NotificationRepository:
    def __init__(self, db: Session):
        self.db = db

    def get_by_id(self, notif_id: str) -> Optional[Notification]:
        return self.db.query(Notification).filter(Notification.id == notif_id).first()

    def list_active(self, skip: int = 0, limit: int = 50) -> List[Notification]:
        return (
            self.db.query(Notification)
            .filter(Notification.is_active == True)
            .order_by(Notification.created_at.desc())
            .offset(skip)
            .limit(limit)
            .all()
        )

    def list_all(self, skip: int = 0, limit: int = 100) -> List[Notification]:
        return (
            self.db.query(Notification)
            .order_by(Notification.created_at.desc())
            .offset(skip)
            .limit(limit)
            .all()
        )

    def create(self, **kwargs) -> Notification:
        notif = Notification(**kwargs)
        self.db.add(notif)
        self.db.commit()
        self.db.refresh(notif)
        return notif

    def delete(self, notif: Notification):
        self.db.delete(notif)
        self.db.commit()

    def mark_read(self, user_id: str, notification_id: str):
        existing = (
            self.db.query(NotificationRead)
            .filter(
                NotificationRead.user_id == user_id,
                NotificationRead.notification_id == notification_id,
            )
            .first()
        )
        if not existing:
            read = NotificationRead(user_id=user_id, notification_id=notification_id)
            self.db.add(read)
            self.db.commit()

    def is_read(self, user_id: str, notification_id: str) -> bool:
        return (
            self.db.query(NotificationRead)
            .filter(
                NotificationRead.user_id == user_id,
                NotificationRead.notification_id == notification_id,
            )
            .first()
            is not None
        )
