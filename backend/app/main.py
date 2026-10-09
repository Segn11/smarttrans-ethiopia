"""
SmartTrans Ethiopia — FastAPI Backend
"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.core.config import settings
from app.api import auth, users, stations, routes, favorites, reports, notifications, admin

app = FastAPI(
    title=settings.APP_NAME,
    version=settings.APP_VERSION,
    description="SmartTrans Ethiopia API — Public Transportation Information Platform for Ethiopian Cities",
    docs_url="/docs",
    redoc_url="/redoc",
)

# ─── CORS ────────────────────────────────────────────────
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins_list,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ─── Routers ─────────────────────────────────────────────
PREFIX = "/api/v1"

app.include_router(auth.router,          prefix=PREFIX)
app.include_router(users.router,         prefix=PREFIX)
app.include_router(stations.router,      prefix=PREFIX)
app.include_router(routes.router,        prefix=PREFIX)
app.include_router(favorites.router,     prefix=PREFIX)
app.include_router(reports.router,       prefix=PREFIX)
app.include_router(notifications.router, prefix=PREFIX)
app.include_router(admin.router,         prefix=PREFIX)


@app.get("/", tags=["Health"])
def health():
    return {
        "success": True,
        "message": f"{settings.APP_NAME} is running",
        "version": settings.APP_VERSION,
    }
