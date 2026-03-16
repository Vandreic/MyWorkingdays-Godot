"""API v1 router configuration.

This module combines all v1 routers into a single router.
New routers should be added here.
"""

from fastapi import APIRouter

from .routers import auth, system

# Create the main v1 router that combines all sub-routers
router = APIRouter()

router.include_router(auth.router, prefix="/auth", tags=["auth"])
router.include_router(system.router, prefix="/system", tags=["system"])