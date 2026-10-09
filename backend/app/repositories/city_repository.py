from typing import Optional, List
from sqlalchemy.orm import Session

from app.models.models import City, TransportType


class CityRepository:
    def __init__(self, db: Session):
        self.db = db

    def get_by_id(self, city_id: str) -> Optional[City]:
        return self.db.query(City).filter(City.id == city_id).first()

    def list_all(self, skip: int = 0, limit: int = 100) -> List[City]:
        return self.db.query(City).offset(skip).limit(limit).all()

    def create(self, **kwargs) -> City:
        city = City(**kwargs)
        self.db.add(city)
        self.db.commit()
        self.db.refresh(city)
        return city

    def update(self, city: City, **kwargs) -> City:
        for k, v in kwargs.items():
            if v is not None:
                setattr(city, k, v)
        self.db.commit()
        self.db.refresh(city)
        return city


class TransportTypeRepository:
    def __init__(self, db: Session):
        self.db = db

    def get_by_id(self, tt_id: str) -> Optional[TransportType]:
        return self.db.query(TransportType).filter(TransportType.id == tt_id).first()

    def list_all(self) -> List[TransportType]:
        return self.db.query(TransportType).filter(TransportType.is_active == True).all()

    def create(self, **kwargs) -> TransportType:
        tt = TransportType(**kwargs)
        self.db.add(tt)
        self.db.commit()
        self.db.refresh(tt)
        return tt
