from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.security import get_current_user
from app.repositories.user_repository import UserRepository
from app.schemas import UserUpdateRequest, UserResponse

router = APIRouter(prefix="/users", tags=["Users"])


@router.get("/me")
def get_me(current_user=Depends(get_current_user)):
    return {"success": True, "data": UserResponse.model_validate(current_user)}


@router.put("/me")
def update_me(
    payload: UserUpdateRequest,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    repo = UserRepository(db)
    user = repo.update(
        current_user,
        name=payload.name,
        phone=payload.phone,
    )
    return {"success": True, "data": UserResponse.model_validate(user)}
