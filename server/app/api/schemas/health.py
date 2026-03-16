"""Health check request and response schemas."""

from pydantic import BaseModel


class HealthResponse(BaseModel):
    """Response model for health check endpoint.

    Attributes:
        status (str): The health status (e.g., "ok").
    """

    status: str