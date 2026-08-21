# AI Document Assistant

AI Document Assistant is a FastAPI + Gemini backend with a Flutter frontend for asking questions about one or more uploaded PDF documents.

## Overview

The app lets a user upload PDFs, extracts and chunks the text, generates embeddings, retrieves the most relevant chunks for each question, and asks Gemini to answer only from the retrieved document context.

The system supports:

- multi-document sessions
- conversational RAG for follow-up questions
- top-k retrieval with similarity filtering
- source tracking for retrieved chunks
- a Flutter UI for upload and chat

## Architecture

```text
Flutter UI
    |
    | HTTP
    v
FastAPI Backend
    |
    +--> PDF extraction
    |
    +--> Chunking
    |
    +--> Gemini embeddings
    |
    +--> Similarity search
    |
    +--> Gemini answer generation
    |
    v
Answer + sources
```

## Features

- Upload multiple PDFs into the same session
- Extract text from uploaded PDFs
- Chunk text into retrievable passages
- Generate Gemini embeddings
- Retrieve top-k relevant chunks
- Filter by similarity threshold
- Use recent chat history to support follow-up questions
- Return source filenames and page information when available
- Clear the current session with one action

## Tech Stack

- Python
- FastAPI
- Pydantic
- pypdf
- NumPy
- google-genai
- Flutter
- http
- file_picker

## Local Setup

### Backend Setup

1. Create and activate a virtual environment.
2. Install dependencies:

```bash
pip install -r requirements.txt
```

3. Create a `.env` file in `project1-openai-chatbot/`:

```env
GEMINI_API_KEY=your_gemini_api_key
CORS_ORIGINS=http://localhost:3000,http://localhost:5173,http://localhost:8000,http://127.0.0.1:3000,http://127.0.0.1:5173,http://127.0.0.1:8000
```

4. Run the backend:

```bash
uvicorn main:app --reload --host 127.0.0.1 --port 8000
```

### Flutter Setup

1. Open the `ai_document_assistant` project.
2. Get dependencies:

```bash
flutter pub get
```

3. Run the app:

```bash
flutter run -d chrome
```

## Production Deployment

### FastAPI Backend

Use a production ASGI server such as `uvicorn` behind a reverse proxy or platform router.

Example:

```bash
uvicorn main:app --host 0.0.0.0 --port 8000
```

Recommended production settings:

- Set `GEMINI_API_KEY` in the hosting environment, not in code
- Set `CORS_ORIGINS` to your deployed Flutter Web domain
- Keep the backend on HTTPS in production
- Do not expose `.env` or uploaded PDFs
- Store only the backend service URL in the Flutter app

If you deploy behind a proxy or load balancer, make sure the proxy forwards requests to the FastAPI port and preserves request body sizes large enough for PDF uploads.

### Flutter Web Frontend

Build the web app for production:

```bash
flutter build web
```

Deploy the generated `build/web` directory to your static hosting platform of choice.

Recommended production settings:

- Point the Flutter app to the deployed backend URL
- Use the backend HTTPS URL in the app's API base URL
- Allow the frontend origin in `CORS_ORIGINS`
- Serve the web app over HTTPS

If you change the backend base URL for production, update the Flutter `ApiService` base URL accordingly before building the web bundle.

## Environment Variables

Backend only:

- `GEMINI_API_KEY`
- `CORS_ORIGINS`

The Flutter app never receives the Gemini API key.

For production, configure these variables in your hosting provider's secret or environment settings rather than in a checked-in file.

## API Endpoints

### `GET /`

Health check.

### `POST /upload`

Upload a PDF file as multipart form data.

Response includes:

- `filename`
- `pages`
- `chunks`

### `POST /ask`

Request body:

```json
{
  "question": "What is the annual leave policy?"
}
```

Response includes:

- `question`
- `answer`
- `sources`

### `GET /documents`

Returns the uploaded document list for the current session.

### `POST /clear`

Clears uploaded documents and conversation memory.

## How RAG Works

1. PDF text is extracted with `pypdf`.
2. The text is chunked into smaller passages.
3. Gemini embeddings are generated for each chunk.
4. A user question is embedded.
5. The backend computes cosine similarity across all uploaded document chunks.
6. The top `TOP_K` chunks are selected.
7. Only chunks above `SIMILARITY_THRESHOLD` are used as context.
8. Gemini answers using only the retrieved context.
9. Recent chat history is included only to interpret follow-up questions, not as source material.

If no retrieved chunk is relevant enough, the backend returns a "not enough information" response without calling Gemini.

## Screenshots

Add screenshots of:

- the upload state
- the document list
- a question/answer chat
- the clear/new document state
