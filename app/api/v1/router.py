"""Main API router."""

from fastapi import APIRouter

from api.v1.heath import router as health_router

api_router = APIRouter()

# Include route modules
api_router.include_router(health_router, tags=["health"])
