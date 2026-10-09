import math
from typing import Optional, List
from sqlalchemy.orm import Session, joinedload

from app.models.models import Station, City


class StationRepository:
    def __init__(self, db: Session):
        self.db = db

    def _base_query(self):
        return self.db.query(Station).options(joinedload(Station.city))

    def get_by_id(self, station_id: str) -> Optional[Station]:
        return self._base_query().filter(Station.id == station_id).first()

    def list_all(self, city_id: Optional[str] = None, skip: int = 0, limit: int = 100) -> List[Station]:
        q = self._base_query()
        if city_id:
            q = q.filter(Station.city_id == city_id)
        return q.offset(skip).limit(limit).all()

    def count(self, city_id: Optional[str] = None) -> int:
        q = self.db.query(Station)
        if city_id:
            q = q.filter(Station.city_id == city_id)
        return q.count()

    def create(self, **kwargs) -> Station:
        station = Station(**kwargs)
        self.db.add(station)
        self.db.commit()
        self.db.refresh(station)
        return self.get_by_id(station.id)

    def update(self, station: Station, **kwargs) -> Station:
        for key, value in kwargs.items():
            if value is not None:
                setattr(station, key, value)
        self.db.commit()
        self.db.refresh(station)
        return self.get_by_id(station.id)

    def delete(self, station: Station):
        self.db.delete(station)
        self.db.commit()

    def get_nearby(self, latitude: float, longitude: float, radius_meters: float) -> List[tuple]:
        """Return list of (station, distance_meters) within radius."""
        all_stations = self._base_query().filter(Station.status == "active").all()
        results = []
        for s in all_stations:
            dist = self._haversine(latitude, longitude, s.latitude, s.longitude)
            if dist <= radius_meters:
                results.append((s, dist))
        results.sort(key=lambda x: x[1])
        return results

    @staticmethod
    def _haversine(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
        """Calculate distance in meters between two lat/lon points."""
        R = 6_371_000  # Earth radius in meters
        phi1, phi2 = math.radians(lat1), math.radians(lat2)
        dphi = math.radians(lat2 - lat1)
        dlambda = math.radians(lon2 - lon1)
        a = math.sin(dphi / 2) ** 2 + math.cos(phi1) * math.cos(phi2) * math.sin(dlambda / 2) ** 2
        return 2 * R * math.atan2(math.sqrt(a), math.sqrt(1 - a))
