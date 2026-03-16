"""Main application entry point.

This module creates and configures the FastAPI application.
It sets up middleware, routes, and runs the server.

Example:
    Run the app from the command line:
        set PYTHONPATH=%CD%
        python -m uvicorn app.main:app --reload


C:\Windows\System32\cmd.exe /k "cd /d D:\SSHD\Programming\Godot\my-workdays\server && set PYTHONPATH=%CD% && python -m uvicorn app.main:app --reload"

"""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.v1 import router as api_v1_router
from app.core.config import settings

# Create the FastAPI application instance
app = FastAPI(
    title=settings.title,
    description=settings.description,
    version=settings.version,
    docs_url="/docs",
    redoc_url="/redoc",
)

# Add CORS middleware to allow cross-origin requests
# This is needed when your API is called from a different domain
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allow all origins (restrict in production)
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include the v1 API routes
app.include_router(api_v1_router, prefix="/api/v1")


@app.get("/")
def read_root() -> dict:
    """Root endpoint that returns a welcome message.

    Returns:
        dict: A dictionary with status and welcome message.
    """
    return {
        "status": "ok",
        "message": "Welcome to FastAPI backend.",
    }


if __name__ == "__main__":
    import uvicorn

    # Run the server with settings from config
    uvicorn.run(app, host=settings.host, port=settings.port)
