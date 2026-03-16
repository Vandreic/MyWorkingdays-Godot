"""Security utilities for API authentication.

This module provides functions and dependencies for protecting
API endpoints with access key authentication.

Example:
    Protect a route with access key authentication::

        from fastapi import Depends
        from app.core.security import require_access_key

        @router.get(
        "/verify",
        response_model=AccessCheckResponse,
        dependencies=[Depends(require_access_key)],
        )
        def verify_access_status() -> AccessCheckResponse:
            return AccessCheckResponse(
                status="ok",
                role="user",
            )
"""

from fastapi import HTTPException, Security, status
from fastapi.security import APIKeyHeader

from app.core.config import settings

# Define the API key header scheme
# This tells FastAPI to look for an "Access-Key" header in requests
api_key_header = APIKeyHeader(name="Access-Key", auto_error=False)


async def require_access_key(
    api_key: str | None = Security(api_key_header),
) -> str:
    """Validate the API key from the request header.

    This is a FastAPI dependency that checks if the request contains
    a valid API key in the "Access-Key" header.

    Args:
        api_key (str | None): The API key extracted from the Access-Key header.

    Returns:
        str: The validated API key if authentication succeeds.

    Raises:
        HTTPException: 403 Forbidden if the API key is missing or invalid.
    """

    # Empty or missing API key
    if api_key is None:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="API key missing. Please provide an 'Access-Key' header.",
        )

    # Invalid API key
    if api_key != settings.global_access_key:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Invalid API key. Access denied.",
        )

    # Valid API key
    return api_key
