from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.security import get_current_user
from app.repositories.notification_repository import NotificationRepository
from app.schemas import NotificationResponse

router = APIRouter(prefix="/notifications", tags=["Notifications"])


@router.get("")
def list_notifications(
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    repo = NotificationRepository(db)
    notifs = repo.list_active()
    data = []
    for n in notifs:
        is_read = repo.is_read(current_user.id, n.id)
        item = NotificationResponse.model_validate(n)
        item.is_read = is_read
        data.append(item)
    return {"success": True, "data": data}


@router.put("/{notification_id}/read")
def mark_read(
    notification_id: str,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    repo = NotificationRepository(db)
    notif = repo.get_by_id(notification_id)
    if not notif:
        raise HTTPException(status_code=404, detail="Notification not found")
    repo.mark_read(current_user.id, notification_id)
    return {"success": True, "message": "Marked as read"}
