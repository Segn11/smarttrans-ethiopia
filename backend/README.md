# SmartTrans Ethiopia — Backend

FastAPI backend for the SmartTrans Ethiopia public transportation platform.

## Setup

### 1. Prerequisites

- Python 3.11+
- pip

### 2. Create Virtual Environment

```bash
python -m venv venv
venv\Scripts\activate      # Windows
source venv/bin/activate   # Linux/macOS
```

### 3. Install Dependencies

```bash
pip install -r requirements.txt
```

### 4. Configure Environment

```bash
copy .env.example .env     # Windows
cp .env.example .env       # Linux/macOS
```

Edit `.env` and fill in:
- `DATABASE_URL` — your Supabase PostgreSQL connection string
- `JWT_SECRET_KEY` — a long random secret (e.g., run `openssl rand -hex 32`)

### 5. Seed the Database

```bash
python scripts/seed.py
```

This will:
- Create all database tables
- Add demo data for Addis Ababa (stations, routes, fares)
- Create admin and demo passenger accounts

**Demo accounts:**
| Role | Email | Password |
|---|---|---|
| Admin | admin@smarttrans.et | Admin@1234 |
| Passenger | passenger@smarttrans.et | Passenger@1234 |

### 6. Run the Server

```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

API docs available at: http://localhost:8000/docs

## Running Tests

```bash
pytest tests/ -v
```

## Project Structure

```
backend/
├── app/
│   ├── api/          # FastAPI route handlers
│   ├── core/         # Config, DB, security
│   ├── models/       # SQLAlchemy models
│   ├── repositories/ # Database access layer
│   ├── schemas/      # Pydantic schemas
│   ├── services/     # Business logic (route search)
│   └── main.py       # FastAPI app entry point
├── scripts/
│   └── seed.py       # Database seed script
├── tests/
│   └── test_api.py   # Pytest test suite
├── .env.example
├── requirements.txt
└── README.md
```

## API Endpoints

### Authentication
| Method | Path | Description |
|---|---|---|
| POST | /api/v1/auth/register | Register |
| POST | /api/v1/auth/login | Login (returns JWT) |
| GET | /api/v1/auth/me | Current user |

### Public
| Method | Path | Description |
|---|---|---|
| GET | /api/v1/stations | List stations |
| GET | /api/v1/stations/nearby | Nearby stations |
| GET | /api/v1/stations/{id} | Station detail |
| GET | /api/v1/routes | List routes |
| GET | /api/v1/routes/search | Search routes |
| GET | /api/v1/routes/{id} | Route detail |

### Authenticated (Passenger+)
| Method | Path | Description |
|---|---|---|
| GET | /api/v1/favorites | My favorites |
| POST | /api/v1/favorites | Add favorite |
| DELETE | /api/v1/favorites/{id} | Remove favorite |
| POST | /api/v1/reports | Submit report |
| GET | /api/v1/reports/my | My reports |
| GET | /api/v1/notifications | Notifications |
| PUT | /api/v1/notifications/{id}/read | Mark as read |

### Admin Only
- All `/api/v1/admin/*` endpoints

## Architecture

```
Flutter Mobile App
       │
       │ REST/JSON
       ↓
FastAPI Backend (this project)
       │
       │ SQLAlchemy
       ↓
Supabase PostgreSQL
```
