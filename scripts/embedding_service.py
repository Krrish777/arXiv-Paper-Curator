"""Standalone embedding service"""

import os
from contextlib import asynccontextmanager
from typing import Any, Dict, List
from unittest import result

import numpy as np
from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException
from huggingface_hub import InferenceClient
from pydantic import BaseModel

# Load environment variables from .env file
load_dotenv()


model = None


class EmbeddingRequest(BaseModel):
    texts: List[str]
    normalize: bool = True


class EmbeddingResponse(BaseModel):
    embeddings: List[List[float]]
    model: str
    dimension: int


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Load the embedding model on startup"""
    global model
    model = InferenceClient(
        provider="hf-inference",
        api_key=os.environ["HF_TOKEN"],
    )
    print("Embedding model loaded")
    yield
    # Cleanup code can go here if needed
    print("Shutting down embedding service")


app = FastAPI(
    title="Embedding Service",
    description="Service for generating embeddings",
    lifespan=lifespan,
)


@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {"status": "healthy", "model": "sentence-transformers/all-MiniLM-L6-v2"}


@app.post("/embed", response_model=EmbeddingResponse)
async def embed_texts(request: EmbeddingRequest):
    """Create embeddings for input texts."""
    if model is None:
        raise HTTPException(status_code=503, detail="Model not loaded")
    try:
        # Use feature_extraction for generating embeddings
        embeddings = model.feature_extraction(
            request.texts, model="sentence-transformers/all-MiniLM-L6-v2"
        )

        # Normalize embeddings if requested
        if request.normalize:
            import numpy as np

            embeddings = [
                (np.array(emb) / np.linalg.norm(emb)).tolist() for emb in embeddings
            ]

        return EmbeddingResponse(
            embeddings=embeddings,
            model="sentence-transformers/all-MiniLM-L6-v2",
            dimension=len(embeddings[0]) if embeddings else 0,
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8001)
