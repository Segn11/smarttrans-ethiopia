"""
SmartTrans Ethiopia — Database Seed Script
==========================================
DEMO DATA — Not official transportation data.

Populates Supabase PostgreSQL with realistic demo data for Addis Ababa.

Usage:
  cd backend
  python scripts/seed.py
"""

import sys
import os

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from dotenv import load_dotenv
load_dotenv()

from sqlalchemy.orm import Session
from app.core.database import engine, Base
from app.core.security import hash_password
from app.models.models import (
    User, City, TransportType, Station, Route,
    RouteStop, Fare, Notification,
)


def seed(db: Session):
    print("🌱 Seeding SmartTrans Ethiopia demo data...")

    # ─── Create Tables ───────────────────────────────────
    Base.metadata.create_all(bind=engine)
    print("  ✓ Tables created")

    # ─── Cities ──────────────────────────────────────────
    addis = City(
        name="Addis Ababa",
        description="Capital city of Ethiopia",
        latitude=9.0320,
        longitude=38.7469,
        is_active=True,
    )
    adama = City(name="Adama", description="City in Oromia region", latitude=8.5400, longitude=39.2700, is_active=True)
    hawassa = City(name="Hawassa", description="Capital of Sidama Region", latitude=7.0604, longitude=38.4767, is_active=True)

    db.add_all([addis, adama, hawassa])
    db.flush()
    print(f"  ✓ Cities added: Addis Ababa, Adama, Hawassa")

    # ─── Transport Types ─────────────────────────────────
    minibus = TransportType(name="Minibus", icon="🚐", description="Blue-and-white shared minibuses (weyane)")
    bus = TransportType(name="Bus", icon="🚌", description="Anbessa City Bus")
    lrt = TransportType(name="LRT", icon="🚊", description="Addis Ababa Light Rail Transit")

    db.add_all([minibus, bus, lrt])
    db.flush()
    print("  ✓ Transport types added: Minibus, Bus, LRT")

    # ─── Stations (Addis Ababa) ───────────────────────────
    stations_data = [
        dict(name="Bole",          city_id=addis.id, latitude=9.0104,  longitude=38.7614, operating_hours="6:00 AM – 10:00 PM"),
        dict(name="Bole Airport",  city_id=addis.id, latitude=9.0184,  longitude=38.7992, operating_hours="5:00 AM – 11:00 PM"),
        dict(name="Mexico",        city_id=addis.id, latitude=9.0135,  longitude=38.7612, operating_hours="6:00 AM – 9:30 PM"),
        dict(name="Piassa",        city_id=addis.id, latitude=9.0365,  longitude=38.7469, operating_hours="6:00 AM – 9:00 PM"),
        dict(name="Arat Kilo",     city_id=addis.id, latitude=9.0458,  longitude=38.7617, operating_hours="6:00 AM – 9:00 PM"),
        dict(name="Stadium",       city_id=addis.id, latitude=9.0219,  longitude=38.7498, operating_hours="6:00 AM – 9:00 PM"),
        dict(name="Merkato",       city_id=addis.id, latitude=9.0302,  longitude=38.7404, operating_hours="6:00 AM – 8:00 PM"),
        dict(name="Kazanchis",     city_id=addis.id, latitude=9.0237,  longitude=38.7618, operating_hours="6:00 AM – 9:30 PM"),
        dict(name="Meskel Square", city_id=addis.id, latitude=9.0168,  longitude=38.7609, operating_hours="6:00 AM – 10:00 PM"),
        dict(name="Lideta",        city_id=addis.id, latitude=9.0099,  longitude=38.7342, operating_hours="6:00 AM – 9:00 PM"),
        dict(name="Saris",         city_id=addis.id, latitude=8.9966,  longitude=38.7480, operating_hours="6:00 AM – 8:30 PM"),
        dict(name="Gofa",          city_id=addis.id, latitude=9.0001,  longitude=38.7318, operating_hours="6:00 AM – 8:00 PM"),
        dict(name="Megenagna",     city_id=addis.id, latitude=9.0541,  longitude=38.7754, operating_hours="6:00 AM – 9:30 PM"),
        dict(name="Ayat",          city_id=addis.id, latitude=9.0607,  longitude=38.8229, operating_hours="6:00 AM – 8:30 PM"),
        dict(name="Lebu",          city_id=addis.id, latitude=8.9761,  longitude=38.7120, operating_hours="6:00 AM – 8:00 PM"),
    ]

    stations = {}
    for sd in stations_data:
        s = Station(**sd, status="active")
        db.add(s)
        db.flush()
        stations[sd["name"]] = s

    print(f"  ✓ {len(stations)} stations added")

    # ─── Routes ──────────────────────────────────────────
    def make_route(name, city_id, tt, time_min, dist_km, hours, stops_names):
        r = Route(
            name=name,
            city_id=city_id,
            transport_type_id=tt.id,
            estimated_time=time_min,
            distance=dist_km,
            operating_hours=hours,
            status="active",
        )
        db.add(r)
        db.flush()
        for order, sname in enumerate(stops_names, 1):
            db.add(RouteStop(route_id=r.id, station_id=stations[sname].id, stop_order=order))
        db.flush()
        return r

    h = "6:00 AM – 9:00 PM"

    r1 = make_route("Bole → Piassa (Minibus)", addis.id, minibus, 40, 8.5, h,
                    ["Bole", "Mexico", "Meskel Square", "Stadium", "Piassa"])

    r2 = make_route("Bole → Piassa (Bus)", addis.id, bus, 50, 8.5, h,
                    ["Bole", "Bole Airport", "Mexico", "Stadium", "Piassa"])

    r3 = make_route("Mexico → Arat Kilo (Minibus)", addis.id, minibus, 20, 4.0, h,
                    ["Mexico", "Stadium", "Piassa", "Arat Kilo"])

    r4 = make_route("Merkato → Megenagna (Minibus)", addis.id, minibus, 35, 7.2, h,
                    ["Merkato", "Piassa", "Arat Kilo", "Kazanchis", "Megenagna"])

    r5 = make_route("Saris → Megenagna (Bus)", addis.id, bus, 55, 14.0, "6:00 AM – 8:30 PM",
                    ["Saris", "Lideta", "Mexico", "Meskel Square", "Kazanchis", "Megenagna"])

    r6 = make_route("Ayat → Piassa (Minibus)", addis.id, minibus, 45, 10.0, h,
                    ["Ayat", "Megenagna", "Kazanchis", "Meskel Square", "Piassa"])

    r7 = make_route("Lebu → Merkato (Minibus)", addis.id, minibus, 30, 6.5, h,
                    ["Lebu", "Gofa", "Lideta", "Merkato"])

    r8 = make_route("Bole → Megenagna (Minibus)", addis.id, minibus, 25, 5.5, "6:00 AM – 10:00 PM",
                    ["Bole", "Mexico", "Kazanchis", "Megenagna"])

    # LRT demo
    r9 = make_route("LRT East–West Line", addis.id, lrt, 35, 17.0, "6:00 AM – 10:00 PM",
                    ["Ayat", "Megenagna", "Mexico", "Lideta", "Stadium"])

    print(f"  ✓ 9 routes added")

    # ─── Fares ───────────────────────────────────────────
    fare_data = [
        (r1, minibus, 30),
        (r2, bus,     20),
        (r3, minibus, 15),
        (r4, minibus, 20),
        (r5, bus,     15),
        (r6, minibus, 25),
        (r7, minibus, 18),
        (r8, minibus, 15),
        (r9, lrt,     10),
    ]
    for route, tt, amount in fare_data:
        db.add(Fare(route_id=route.id, transport_type_id=tt.id, amount=amount, currency="ETB"))

    print("  ✓ Fares added")

    # ─── Admin User ──────────────────────────────────────
    admin_user = User(
        name="SmartTrans Admin",
        email="admin@smarttrans.et",
        hashed_password=hash_password("Admin@1234"),
        role="admin",
        phone="+251911000001",
    )
    passenger = User(
        name="Demo Passenger",
        email="passenger@smarttrans.et",
        hashed_password=hash_password("Passenger@1234"),
        role="passenger",
        phone="+251922000002",
    )
    db.add_all([admin_user, passenger])

    # ─── Sample Notifications ────────────────────────────
    notif1 = Notification(
        title="Welcome to SmartTrans Ethiopia!",
        message="Find your routes easily across Addis Ababa and more Ethiopian cities.",
        notification_type="info",
        is_active=True,
    )
    notif2 = Notification(
        title="Route Update",
        message="The Bole → Piassa route via Minibus has been temporarily changed due to road work near Mexico.",
        notification_type="warning",
        is_active=True,
    )
    db.add_all([notif1, notif2])

    db.commit()
    print("  ✓ Admin user and demo passenger added")
    print("  ✓ Sample notifications added")
    print()
    print("✅ Seed complete!")
    print()
    print("Demo accounts:")
    print("  Admin:     admin@smarttrans.et      / Admin@1234")
    print("  Passenger: passenger@smarttrans.et  / Passenger@1234")


if __name__ == "__main__":
    from sqlalchemy.orm import sessionmaker

    SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
    db = SessionLocal()
    try:
        seed(db)
    except Exception as e:
        db.rollback()
        print(f"❌ Seed failed: {e}")
        raise
    finally:
        db.close()
