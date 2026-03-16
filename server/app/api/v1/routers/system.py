"""System routes.

This module contains endpoints for system health and status checks.
"""

from fastapi import APIRouter

from app.api.schemas.health import HealthResponse

router = APIRouter()


@router.get("/health", response_model=HealthResponse)
def health_check() -> HealthResponse:
    """Check if the API is running.

    This endpoint does not require authentication.
    Use it for monitoring and load balancer health checks.

    Returns:
        HealthResponse: Response with status "ok" if the API is healthy.
    """
    return HealthResponse(status="ok")