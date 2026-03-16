"""Authentication routes.

This module contains endpoints for verifying API access.
"""

from fastapi import APIRouter, Depends

from app.api.schemas.access import AccessCheckResponse
from app.core.security import require_access_key

router = APIRouter()


@router.get(
    "/verify",
    response_model=AccessCheckResponse,
    dependencies=[Depends(require_access_key)],
)
def verify_access_status() -> AccessCheckResponse:
    """Verify that the provided API key is valid.

    This endpoint requires a valid Access-Key header.
    If the key is valid, it returns the user's access status.

    Returns:
        AccessCheckResponse: Response with status and role information.
    """
    return AccessCheckResponse(
        status="ok",
        role="user",
    )