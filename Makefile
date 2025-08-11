.PHONY: help dev-up dev-down test lint format check

# Default target
help:
	@echo "Available commands:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

# Service Management
dev-up:
	docker compose up -d
	@echo "Services starting... Run 'make logs' to monitor"

dev-down:
	docker compose down

restart:
	docker compose restart

status:
	docker compose ps

logs:
	docker compose logs -f

# Development
setup:
	uv sync

format:
	uv run ruff format .

lint:
	uv run ruff check .
	uv run mypy .

test:
	uv run pytest

test-coverage:
	uv run pytest --cov=src 


# Health Check
health:
	curl -s http://localhost:8000/health | jq

# Cleanup
cleanup:
	docker compose down -v
	docker system prune -f