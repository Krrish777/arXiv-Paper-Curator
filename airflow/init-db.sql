-- Database initialization script for arXiv RAG system
-- This script sets up the necessary database schema for production-grade RAG

-- Create extensions required for RAG system
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
-- CRITICAL: pgvector extension for vector similarity search
CREATE EXTENSION IF NOT EXISTS "vector";

-- Create application schema
CREATE SCHEMA IF NOT EXISTS rag_app;

-- Grant permissions to the rag_user
GRANT ALL PRIVILEGES ON SCHEMA rag_app TO rag_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA rag_app TO rag_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA rag_app TO rag_user;

-- Documents table - stores arXiv papers and metadata
CREATE TABLE IF NOT EXISTS rag_app.documents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    arxiv_id VARCHAR(50) UNIQUE NOT NULL,  -- arXiv paper ID
    title VARCHAR(1000) NOT NULL,
    abstract TEXT,
    authors TEXT[],  -- Array of author names
    categories TEXT[],  -- arXiv categories
    published_date DATE,
    updated_date DATE,
    pdf_url VARCHAR(500),
    full_text TEXT,  -- Complete paper content
    metadata JSONB DEFAULT '{}',
    processing_status VARCHAR(50) DEFAULT 'pending',  -- pending, processing, completed, failed
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Document chunks table - for RAG retrieval
CREATE TABLE IF NOT EXISTS rag_app.document_chunks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    document_id UUID REFERENCES rag_app.documents(id) ON DELETE CASCADE,
    chunk_index INTEGER NOT NULL,  -- Order within document
    content TEXT NOT NULL,
    chunk_type VARCHAR(50) DEFAULT 'text',  -- text, abstract, conclusion, etc.
    word_count INTEGER,
    char_count INTEGER,
    embedding vector(768),  -- 768-dimensional embeddings (adjust based on model)
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Queries table - logs user interactions
CREATE TABLE IF NOT EXISTS rag_app.queries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    query_text TEXT NOT NULL,
    query_embedding vector(768),  -- Query embedding for similarity search
    retrieved_chunks JSONB DEFAULT '[]',  -- Array of retrieved chunk IDs
    generated_response TEXT,
    response_metadata JSONB DEFAULT '{}',
    execution_time_ms INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Search sessions table - for conversation tracking
CREATE TABLE IF NOT EXISTS rag_app.search_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_token VARCHAR(255) UNIQUE NOT NULL,
    user_id VARCHAR(255),  -- Optional user identification
    context JSONB DEFAULT '{}',  -- Conversation context
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_accessed TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Embeddings model registry - track different embedding models
CREATE TABLE IF NOT EXISTS rag_app.embedding_models (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    model_name VARCHAR(255) UNIQUE NOT NULL,
    model_version VARCHAR(100),
    dimension INTEGER NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Performance indexes for vector similarity search
CREATE INDEX IF NOT EXISTS idx_chunks_embedding ON rag_app.document_chunks 
USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);

-- Traditional indexes for metadata queries
CREATE INDEX IF NOT EXISTS idx_documents_arxiv_id ON rag_app.documents(arxiv_id);
CREATE INDEX IF NOT EXISTS idx_documents_categories ON rag_app.documents USING GIN(categories);
CREATE INDEX IF NOT EXISTS idx_documents_published_date ON rag_app.documents(published_date);
CREATE INDEX IF NOT EXISTS idx_documents_status ON rag_app.documents(processing_status);
CREATE INDEX IF NOT EXISTS idx_chunks_document_id ON rag_app.document_chunks(document_id);
CREATE INDEX IF NOT EXISTS idx_chunks_type ON rag_app.document_chunks(chunk_type);
CREATE INDEX IF NOT EXISTS idx_queries_created_at ON rag_app.queries(created_at);
CREATE INDEX IF NOT EXISTS idx_sessions_token ON rag_app.search_sessions(session_token);
CREATE INDEX IF NOT EXISTS idx_sessions_last_accessed ON rag_app.search_sessions(last_accessed);

-- Update permissions for new tables
ALTER TABLE rag_app.documents OWNER TO rag_user;
ALTER TABLE rag_app.document_chunks OWNER TO rag_user;
ALTER TABLE rag_app.queries OWNER TO rag_user;
ALTER TABLE rag_app.search_sessions OWNER TO rag_user;
ALTER TABLE rag_app.embedding_models OWNER TO rag_user;

-- Insert default embedding model
INSERT INTO rag_app.embedding_models (model_name, model_version, dimension, description, is_active)
VALUES ('thenlper/gte-base', 'v1.0', 768, 'General Text Embedding Base Model from HuggingFace', true)
ON CONFLICT (model_name) DO NOTHING;