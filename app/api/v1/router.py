"""Main API router."""

from fastapi import APIRouter

from api.v1 import health_router

api_router = APIRouter()

# Include route modules
api_router.include_router(health_router, tags=["health"])
