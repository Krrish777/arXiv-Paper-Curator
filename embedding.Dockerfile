# Optimized Dockerfile for HuggingFace Embedding Service
# Designed for CPU inference with minimal image size and security best practices

FROM python:3.12-slim

# Set working directory
WORKDIR /app

# Install system dependencies for HuggingFace transformers and uv
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    curl \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Install uv for faster package management
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

# Create non-root user for security
RUN groupadd -r embedding && useradd -r -g embedding embedding

# Copy requirements first for better Docker layer caching
COPY requirements.embedding.txt ./requirements.txt

# Install Python dependencies with uv (much faster than pip)
# Install PyTorch CPU version first from CPU-specific index
RUN uv pip install --system --no-cache \
    torch==2.4.0+cpu \
    --index-url https://download.pytorch.org/whl/cpu

# Install remaining dependencies
RUN uv pip install --system --no-cache -r requirements.txt

# Copy embedding service code
COPY scripts/embedding_service.py ./embedding_service.py

# Create cache directory with proper permissions
RUN mkdir -p /app/cache && \
    chown -R embedding:embedding /app && \
    chmod 755 /app/cache

# Switch to non-root user for security
USER embedding

# Set environment variables for optimization
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1
ENV HF_HOME=/app/cache
ENV TRANSFORMERS_CACHE=/app/cache
ENV TOKENIZERS_PARALLELISM=false

# Expose port
EXPOSE 8001

# Health check with proper timeout
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8001/health', timeout=5)"

# Run the embedding service with optimized settings
CMD ["python", "-m", "uvicorn", "embedding_service:app", \
     "--host", "0.0.0.0", \
     "--port", "8001", \
     "--workers", "1", \
     "--access-log", \
     "--log-level", "info"]
