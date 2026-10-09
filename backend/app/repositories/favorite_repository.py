from typing import Optional, List
from sqlalchemy.orm import Session, joinedload

from app.models.models import Favorite, Route, RouteStop, Fare, TransportType


class FavoriteRepository:
    def __init__(self, db: Session):
        self.db = db

    def get_by_id(self, fav_id: str) -> Optional[Favorite]:
        return (
            self.db.query(Favorite)
            .options(
                joinedload(Favorite.route).joinedload(Route.transport_type),
                joinedload(Favorite.route).joinedload(Route.route_stops).joinedload(RouteStop.station),
                joinedload(Favorite.route).joinedload(Route.fares).joinedload(Fare.transport_type),
            )
            .filter(Favorite.id == fav_id)
            .first()
        )

    def list_by_user(self, user_id: str) -> List[Favorite]:
        return (
            self.db.query(Favorite)
            .options(
                joinedload(Favorite.route).joinedload(Route.transport_type),
                joinedload(Favorite.route).joinedload(Route.route_stops).joinedload(RouteStop.station),
                joinedload(Favorite.route).joinedload(Route.fares).joinedload(Fare.transport_type),
            )
            .filter(Favorite.user_id == user_id)
            .all()
        )

    def exists(self, user_id: str, route_id: str) -> bool:
        return (
            self.db.query(Favorite)
            .filter(Favorite.user_id == user_id, Favorite.route_id == route_id)
            .first()
            is not None
        )

    def create(self, user_id: str, route_id: str, label: Optional[str] = None) -> Favorite:
        fav = Favorite(user_id=user_id, route_id=route_id, label=label)
        self.db.add(fav)
        self.db.commit()
        self.db.refresh(fav)
        return self.get_by_id(fav.id)

    def delete(self, fav: Favorite):
        self.db.delete(fav)
        self.db.commit()
