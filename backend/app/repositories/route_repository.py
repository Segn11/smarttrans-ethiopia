from typing import Optional, List
from sqlalchemy.orm import Session, joinedload

from app.models.models import Route, RouteStop, Fare, TransportType


class RouteRepository:
    def __init__(self, db: Session):
        self.db = db

    def _base_query(self):
        return (
            self.db.query(Route)
            .options(
                joinedload(Route.transport_type),
                joinedload(Route.route_stops).joinedload(RouteStop.station),
                joinedload(Route.fares).joinedload(Fare.transport_type),
            )
        )

    def get_by_id(self, route_id: str) -> Optional[Route]:
        return self._base_query().filter(Route.id == route_id).first()

    def list_all(self, city_id: Optional[str] = None, status: Optional[str] = None,
                 skip: int = 0, limit: int = 100) -> List[Route]:
        q = self._base_query()
        if city_id:
            q = q.filter(Route.city_id == city_id)
        if status:
            q = q.filter(Route.status == status)
        return q.offset(skip).limit(limit).all()

    def count(self, city_id: Optional[str] = None, status: Optional[str] = None) -> int:
        q = self.db.query(Route)
        if city_id:
            q = q.filter(Route.city_id == city_id)
        if status:
            q = q.filter(Route.status == status)
        return q.count()

    def create(self, **kwargs) -> Route:
        route = Route(**kwargs)
        self.db.add(route)
        self.db.commit()
        self.db.refresh(route)
        return self.get_by_id(route.id)

    def update(self, route: Route, **kwargs) -> Route:
        for key, value in kwargs.items():
            if value is not None:
                setattr(route, key, value)
        self.db.commit()
        self.db.refresh(route)
        return self.get_by_id(route.id)

    def delete(self, route: Route):
        self.db.delete(route)
        self.db.commit()

    # ─── Route Stops ────────────────────────────────────────

    def add_stop(self, route_id: str, station_id: str, stop_order: int) -> RouteStop:
        stop = RouteStop(route_id=route_id, station_id=station_id, stop_order=stop_order)
        self.db.add(stop)
        self.db.commit()
        self.db.refresh(stop)
        return stop

    def remove_stop(self, stop_id: str):
        stop = self.db.query(RouteStop).filter(RouteStop.id == stop_id).first()
        if stop:
            self.db.delete(stop)
            self.db.commit()

    def get_stops(self, route_id: str) -> List[RouteStop]:
        return (
            self.db.query(RouteStop)
            .filter(RouteStop.route_id == route_id)
            .options(joinedload(RouteStop.station))
            .order_by(RouteStop.stop_order)
            .all()
        )

    def get_all_active_routes(self) -> List[Route]:
        return self._base_query().filter(Route.status == "active").all()


class FareRepository:
    def __init__(self, db: Session):
        self.db = db

    def get_by_id(self, fare_id: str) -> Optional[Fare]:
        return (
            self.db.query(Fare)
            .options(joinedload(Fare.transport_type))
            .filter(Fare.id == fare_id)
            .first()
        )

    def list_all(self, route_id: Optional[str] = None, skip: int = 0, limit: int = 100) -> List[Fare]:
        q = self.db.query(Fare).options(joinedload(Fare.transport_type))
        if route_id:
            q = q.filter(Fare.route_id == route_id)
        return q.offset(skip).limit(limit).all()

    def create(self, **kwargs) -> Fare:
        fare = Fare(**kwargs)
        self.db.add(fare)
        self.db.commit()
        self.db.refresh(fare)
        return self.get_by_id(fare.id)

    def update(self, fare: Fare, **kwargs) -> Fare:
        for key, value in kwargs.items():
            if value is not None:
                setattr(fare, key, value)
        self.db.commit()
        self.db.refresh(fare)
        return self.get_by_id(fare.id)

    def delete(self, fare: Fare):
        self.db.delete(fare)
        self.db.commit()
