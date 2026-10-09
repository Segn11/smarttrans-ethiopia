from typing import Optional, List
from pydantic import BaseModel


# ─── City ───────────────────────────────────────────────

class CityCreate(BaseModel):
    name: str
    description: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None


class CityUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    is_active: Optional[bool] = None


class CityResponse(BaseModel):
    id: str
    name: str
    description: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    is_active: bool

    model_config = {"from_attributes": True}


# ─── TransportType ──────────────────────────────────────

class TransportTypeCreate(BaseModel):
    name: str
    icon: Optional[str] = None
    description: Optional[str] = None


class TransportTypeResponse(BaseModel):
    id: str
    name: str
    icon: Optional[str] = None
    description: Optional[str] = None
    is_active: bool

    model_config = {"from_attributes": True}


# ─── Station ────────────────────────────────────────────

class StationCreate(BaseModel):
    name: str
    description: Optional[str] = None
    city_id: str
    latitude: float
    longitude: float
    operating_hours: Optional[str] = None
    status: str = "active"


class StationUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    operating_hours: Optional[str] = None
    status: Optional[str] = None


class StationResponse(BaseModel):
    id: str
    name: str
    description: Optional[str] = None
    city_id: str
    latitude: float
    longitude: float
    operating_hours: Optional[str] = None
    status: str
    city: Optional[CityResponse] = None

    model_config = {"from_attributes": True}


class NearbyStationResponse(BaseModel):
    station: StationResponse
    distance_meters: float


# ─── RouteStop ──────────────────────────────────────────

class RouteStopCreate(BaseModel):
    station_id: str
    stop_order: int


class RouteStopResponse(BaseModel):
    id: str
    route_id: str
    station_id: str
    stop_order: int
    station: Optional[StationResponse] = None

    model_config = {"from_attributes": True}


# ─── Fare ───────────────────────────────────────────────

class FareCreate(BaseModel):
    route_id: str
    transport_type_id: str
    amount: float
    currency: str = "ETB"


class FareUpdate(BaseModel):
    amount: Optional[float] = None
    currency: Optional[str] = None


class FareResponse(BaseModel):
    id: str
    route_id: str
    transport_type_id: str
    amount: float
    currency: str
    transport_type: Optional[TransportTypeResponse] = None

    model_config = {"from_attributes": True}


# ─── Route ──────────────────────────────────────────────

class RouteCreate(BaseModel):
    name: str
    city_id: str
    transport_type_id: str
    estimated_time: Optional[int] = None
    distance: Optional[float] = None
    operating_hours: Optional[str] = None
    status: str = "active"


class RouteUpdate(BaseModel):
    name: Optional[str] = None
    transport_type_id: Optional[str] = None
    estimated_time: Optional[int] = None
    distance: Optional[float] = None
    operating_hours: Optional[str] = None
    status: Optional[str] = None


class RouteResponse(BaseModel):
    id: str
    name: str
    city_id: str
    transport_type_id: str
    estimated_time: Optional[int] = None
    distance: Optional[float] = None
    operating_hours: Optional[str] = None
    status: str
    transport_type: Optional[TransportTypeResponse] = None
    route_stops: List[RouteStopResponse] = []
    fares: List[FareResponse] = []

    model_config = {"from_attributes": True}


# ─── Route Search ───────────────────────────────────────

class RouteSearchResult(BaseModel):
    route: RouteResponse
    sort_key_time: Optional[int] = None
    sort_key_fare: Optional[float] = None
    transfers: int = 0


# ─── Favorite ───────────────────────────────────────────

class FavoriteCreate(BaseModel):
    route_id: str
    label: Optional[str] = None


class FavoriteResponse(BaseModel):
    id: str
    user_id: str
    route_id: str
    label: Optional[str] = None
    route: Optional[RouteResponse] = None

    model_config = {"from_attributes": True}


# ─── Report ─────────────────────────────────────────────

class ReportCreate(BaseModel):
    route_id: Optional[str] = None
    report_type: str
    description: str


class ReportStatusUpdate(BaseModel):
    status: str
    admin_notes: Optional[str] = None


class ReportResponse(BaseModel):
    id: str
    user_id: Optional[str] = None
    route_id: Optional[str] = None
    report_type: str
    description: str
    status: str
    admin_notes: Optional[str] = None

    model_config = {"from_attributes": True}


# ─── Notification ────────────────────────────────────────

class NotificationCreate(BaseModel):
    title: str
    message: str
    notification_type: str = "info"


class NotificationResponse(BaseModel):
    id: str
    title: str
    message: str
    notification_type: str
    is_active: bool
    is_read: bool = False

    model_config = {"from_attributes": True}


# ─── Admin Dashboard ─────────────────────────────────────

class DashboardStats(BaseModel):
    total_users: int
    total_stations: int
    total_routes: int
    total_reports: int
    active_routes: int
    pending_reports: int
