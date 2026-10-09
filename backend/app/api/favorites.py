from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.security import get_current_user
from app.repositories.favorite_repository import FavoriteRepository
from app.repositories.route_repository import RouteRepository
from app.schemas import FavoriteCreate, FavoriteResponse

router = APIRouter(prefix="/favorites", tags=["Favorites"])


@router.get("")
def list_favorites(current_user=Depends(get_current_user), db: Session = Depends(get_db)):
    repo = FavoriteRepository(db)
    favs = repo.list_by_user(current_user.id)
    return {"success": True, "data": [FavoriteResponse.model_validate(f) for f in favs]}


@router.post("", status_code=status.HTTP_201_CREATED)
def add_favorite(
    payload: FavoriteCreate,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    # Validate route exists
    route_repo = RouteRepository(db)
    route = route_repo.get_by_id(payload.route_id)
    if not route:
        raise HTTPException(status_code=404, detail="Route not found")

    repo = FavoriteRepository(db)
    if repo.exists(current_user.id, payload.route_id):
        raise HTTPException(status_code=409, detail="Route already in favorites")

    fav = repo.create(user_id=current_user.id, route_id=payload.route_id, label=payload.label)
    return {"success": True, "data": FavoriteResponse.model_validate(fav)}


@router.delete("/{favorite_id}", status_code=status.HTTP_200_OK)
def remove_favorite(
    favorite_id: str,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    repo = FavoriteRepository(db)
    fav = repo.get_by_id(favorite_id)
    if not fav:
        raise HTTPException(status_code=404, detail="Favorite not found")
    if fav.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized")
    repo.delete(fav)
    return {"success": True, "message": "Removed from favorites"}
