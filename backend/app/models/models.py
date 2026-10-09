import uuid
from datetime import datetime
from sqlalchemy import (
    Column, String, Boolean, DateTime, Float, Integer, Text,
    ForeignKey, Enum, UniqueConstraint
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.core.database import Base


def gen_uuid():
    return str(uuid.uuid4())


# ─────────────────────────────────────────────────────────
# User
# ─────────────────────────────────────────────────────────
class User(Base):
    __tablename__ = "users"

    id = Column(UUID(as_uuid=False), primary_key=True, default=gen_uuid)
    name = Column(String(100), nullable=False)
    email = Column(String(255), unique=True, nullable=False, index=True)
    phone = Column(String(20), nullable=True)
    hashed_password = Column(String(255), nullable=False)
    role = Column(Enum("passenger", "admin", name="user_role"), default="passenger", nullable=False)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    favorites = relationship("Favorite", back_populates="user", cascade="all, delete-orphan")
    reports = relationship("Report", back_populates="user", cascade="all, delete-orphan")
    notification_reads = relationship("NotificationRead", back_populates="user", cascade="all, delete-orphan")


# ─────────────────────────────────────────────────────────
# City
# ─────────────────────────────────────────────────────────
class City(Base):
    __tablename__ = "cities"

    id = Column(UUID(as_uuid=False), primary_key=True, default=gen_uuid)
    name = Column(String(100), unique=True, nullable=False)
    description = Column(Text, nullable=True)
    latitude = Column(Float, nullable=True)
    longitude = Column(Float, nullable=True)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    stations = relationship("Station", back_populates="city")
    routes = relationship("Route", back_populates="city")


# ─────────────────────────────────────────────────────────
# TransportType
# ─────────────────────────────────────────────────────────
class TransportType(Base):
    __tablename__ = "transport_types"

    id = Column(UUID(as_uuid=False), primary_key=True, default=gen_uuid)
    name = Column(String(100), unique=True, nullable=False)   # e.g. Minibus, Bus, LRT
    icon = Column(String(50), nullable=True)                   # emoji or icon key
    description = Column(Text, nullable=True)
    is_active = Column(Boolean, default=True)

    routes = relationship("Route", back_populates="transport_type")
    fares = relationship("Fare", back_populates="transport_type")


# ─────────────────────────────────────────────────────────
# Station
# ─────────────────────────────────────────────────────────
class Station(Base):
    __tablename__ = "stations"

    id = Column(UUID(as_uuid=False), primary_key=True, default=gen_uuid)
    name = Column(String(150), nullable=False)
    description = Column(Text, nullable=True)
    city_id = Column(UUID(as_uuid=False), ForeignKey("cities.id", ondelete="RESTRICT"), nullable=False)
    latitude = Column(Float, nullable=False)
    longitude = Column(Float, nullable=False)
    operating_hours = Column(String(100), nullable=True)   # e.g. "6:00 AM – 9:00 PM"
    status = Column(Enum("active", "inactive", "maintenance", name="station_status"), default="active")
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    city = relationship("City", back_populates="stations")
    route_stops = relationship("RouteStop", back_populates="station")


# ─────────────────────────────────────────────────────────
# Route
# ─────────────────────────────────────────────────────────
class Route(Base):
    __tablename__ = "routes"

    id = Column(UUID(as_uuid=False), primary_key=True, default=gen_uuid)
    name = Column(String(200), nullable=False)
    city_id = Column(UUID(as_uuid=False), ForeignKey("cities.id", ondelete="RESTRICT"), nullable=False)
    transport_type_id = Column(UUID(as_uuid=False), ForeignKey("transport_types.id", ondelete="RESTRICT"), nullable=False)
    estimated_time = Column(Integer, nullable=True)    # minutes
    distance = Column(Float, nullable=True)            # kilometers
    operating_hours = Column(String(100), nullable=True)
    status = Column(Enum("active", "inactive", "suspended", name="route_status"), default="active")
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    city = relationship("City", back_populates="routes")
    transport_type = relationship("TransportType", back_populates="routes")
    route_stops = relationship("RouteStop", back_populates="route", order_by="RouteStop.stop_order", cascade="all, delete-orphan")
    fares = relationship("Fare", back_populates="route", cascade="all, delete-orphan")
    favorites = relationship("Favorite", back_populates="route", cascade="all, delete-orphan")


# ─────────────────────────────────────────────────────────
# RouteStop
# ─────────────────────────────────────────────────────────
class RouteStop(Base):
    __tablename__ = "route_stops"
    __table_args__ = (
        UniqueConstraint("route_id", "stop_order", name="uq_route_stop_order"),
    )

    id = Column(UUID(as_uuid=False), primary_key=True, default=gen_uuid)
    route_id = Column(UUID(as_uuid=False), ForeignKey("routes.id", ondelete="CASCADE"), nullable=False)
    station_id = Column(UUID(as_uuid=False), ForeignKey("stations.id", ondelete="RESTRICT"), nullable=False)
    stop_order = Column(Integer, nullable=False)

    route = relationship("Route", back_populates="route_stops")
    station = relationship("Station", back_populates="route_stops")


# ─────────────────────────────────────────────────────────
# Fare
# ─────────────────────────────────────────────────────────
class Fare(Base):
    __tablename__ = "fares"

    id = Column(UUID(as_uuid=False), primary_key=True, default=gen_uuid)
    route_id = Column(UUID(as_uuid=False), ForeignKey("routes.id", ondelete="CASCADE"), nullable=False)
    transport_type_id = Column(UUID(as_uuid=False), ForeignKey("transport_types.id", ondelete="RESTRICT"), nullable=False)
    amount = Column(Float, nullable=False)
    currency = Column(String(10), default="ETB")
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    route = relationship("Route", back_populates="fares")
    transport_type = relationship("TransportType", back_populates="fares")


# ─────────────────────────────────────────────────────────
# Favorite
# ─────────────────────────────────────────────────────────
class Favorite(Base):
    __tablename__ = "favorites"
    __table_args__ = (
        UniqueConstraint("user_id", "route_id", name="uq_favorite_user_route"),
    )

    id = Column(UUID(as_uuid=False), primary_key=True, default=gen_uuid)
    user_id = Column(UUID(as_uuid=False), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    route_id = Column(UUID(as_uuid=False), ForeignKey("routes.id", ondelete="CASCADE"), nullable=False)
    label = Column(String(150), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    user = relationship("User", back_populates="favorites")
    route = relationship("Route", back_populates="favorites")


# ─────────────────────────────────────────────────────────
# Report
# ─────────────────────────────────────────────────────────
class Report(Base):
    __tablename__ = "reports"

    id = Column(UUID(as_uuid=False), primary_key=True, default=gen_uuid)
    user_id = Column(UUID(as_uuid=False), ForeignKey("users.id", ondelete="SET NULL"), nullable=True)
    route_id = Column(UUID(as_uuid=False), ForeignKey("routes.id", ondelete="SET NULL"), nullable=True)
    report_type = Column(
        Enum(
            "route_unavailable", "station_closed", "fare_changed",
            "heavy_traffic", "incorrect_info", "other",
            name="report_type_enum",
        ),
        nullable=False,
    )
    description = Column(Text, nullable=False)
    status = Column(
        Enum("pending", "under_review", "verified", "rejected", "resolved", name="report_status_enum"),
        default="pending",
    )
    admin_notes = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    user = relationship("User", back_populates="reports")


# ─────────────────────────────────────────────────────────
# Notification
# ─────────────────────────────────────────────────────────
class Notification(Base):
    __tablename__ = "notifications"

    id = Column(UUID(as_uuid=False), primary_key=True, default=gen_uuid)
    title = Column(String(200), nullable=False)
    message = Column(Text, nullable=False)
    notification_type = Column(String(50), default="info")
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    reads = relationship("NotificationRead", back_populates="notification", cascade="all, delete-orphan")


# ─────────────────────────────────────────────────────────
# NotificationRead
# ─────────────────────────────────────────────────────────
class NotificationRead(Base):
    __tablename__ = "notification_reads"
    __table_args__ = (
        UniqueConstraint("user_id", "notification_id", name="uq_notif_read_user"),
    )

    id = Column(UUID(as_uuid=False), primary_key=True, default=gen_uuid)
    user_id = Column(UUID(as_uuid=False), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    notification_id = Column(UUID(as_uuid=False), ForeignKey("notifications.id", ondelete="CASCADE"), nullable=False)
    read_at = Column(DateTime(timezone=True), server_default=func.now())

    user = relationship("User", back_populates="notification_reads")
    notification = relationship("Notification", back_populates="reads")
