# Server (FastAPI)

> **Based on [Godot-FastAPI Auth Template](https://github.com/Vandreic/Godot-FastAPI-Auth-Template).** For full setup, environment variables, and phone testing, see the template repository.

The backend API built with **Python** and **FastAPI**. Handles access key authentication and provides endpoints for the Godot client.

## Features

- 🔐 Access key authentication via HTTP headers
- 📡 RESTful API with versioning (`/api/v1`)
- 📖 Auto-generated API docs (Swagger UI)
- ⚙️ Environment-based configuration

## How It Communicates with the Client

The server receives HTTP requests from the Godot client and returns JSON responses.

### Request Flow

```
Client Request                          Server Processing
─────────────────                       ─────────────────
GET /api/v1/auth/verify      ───▶      1. Extract Access-Key header
Header: Access-Key: xxx                 2. Validate against .env secret
                                        3. Return JSON response
                             ◀───      
{                                       
  "status": "ok",                       
  "role": "user"                        
}
```

### Authentication Flow

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Client    │     │  security   │     │   .env      │
│  (Godot)    │     │  .py        │     │   file      │
└──────┬──────┘     └──────┬──────┘     └──────┬──────┘
       │                   │                   │
       │ Access-Key: xxx   │                   │
       │──────────────────▶│                   │
       │                   │ GLOBAL_ACCESS_KEY │
       │                   │◀──────────────────│
       │                   │                   │
       │                   │ Compare keys      │
       │                   │                   │
       │ 200 OK / 403 Error│                   │
       │◀──────────────────│                   │
```

### API Endpoints

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/` | Welcome message | No |
| GET | `/api/v1/system/health` | Server health check | No |
| GET | `/api/v1/auth/verify` | Verify access key | Yes |

### Example Requests

**Health Check (no auth):**
```bash
curl http://localhost:8000/api/v1/system/health
```

**Verify Access Key:**
```bash
curl -H "Access-Key: your-secret-key" http://localhost:8000/api/v1/auth/verify
```

## Project Structure

```
server/
├── .env                    # Secret access key (create this)
├── requirements.txt        # Python dependencies
└── app/
    ├── main.py             # FastAPI app entry point
    ├── api/
    │   ├── schemas/        # Pydantic response models
    │   └── v1/routers/     # API route handlers
    │       ├── auth.py     # /auth/verify endpoint
    │       └── system.py   # /system/health endpoint
    └── core/
        ├── config.py       # Settings from .env
        └── security.py     # Access key validation
```

## Setup

1. Navigate to this folder:
   ```bash
   cd server
   ```

2. Create a virtual environment:
   ```bash
   python -m venv .venv
   ```

3. Activate it:
   ```bash
   # Windows
   .venv\Scripts\activate
   
   # macOS/Linux
   source .venv/bin/activate
   ```

4. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```

5. Create `.env` file:
   ```env
   GLOBAL_ACCESS_KEY=your-secret-key-here
   ```

6. Run the server:
   ```bash
   uvicorn app.main:app --reload
   ```

7. Open API docs: http://localhost:8000/docs

## Configuration

Edit `.env` to configure:

| Variable | Required | Description |
|----------|----------|-------------|
| `GLOBAL_ACCESS_KEY` | Yes | Secret key for authentication |
| `HOST` | No | Server host (default: `localhost`) |
| `PORT` | No | Server port (default: `8000`) |
| `DEBUG` | No | Enable debug mode (default: `false`) |