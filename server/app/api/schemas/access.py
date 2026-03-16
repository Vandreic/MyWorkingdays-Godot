"""Access-related request and response schemas."""

from pydantic import BaseModel


class AccessCheckResponse(BaseModel):
    """Response model for access verification.

    Attributes:
        status (str): The result of the access check (e.g., "ok").
        role (str): The user's role (e.g., "user", "admin").
    """

    status: str
    role: str