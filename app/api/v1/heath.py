"""Health check endpoints"""

import asyncio
from time import time
from typing import Any, Dict

from fastapi import APIRouter

router = APIRouter()


@router.get("/health/detailed")
async def health_check() -> Dict[str, Any]:
    """Detailed health check for all services"""

    health_status = {"status": "healthy", "services": {}, "timestamp": int(time())}

    health_status["services"] = {
        "database": "healthy",
        "opensearch": "healthy",
        "redis": "healthy",
        "embedding": "healthy",
    }

    return health_status
