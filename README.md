# AI Document Assistant

AI Document Assistant is a full-stack PDF question-answering app built with a FastAPI backend, Gemini, and a Flutter Web frontend.

It supports multi-PDF conversational RAG, source citations, and PDF-aware answers grounded only in uploaded documents.

## Architecture

```text
Flutter
  -> FastAPI
  -> PDF Processing
  -> Chunking
  -> Gemini Embeddings
  -> Similarity Search
  -> Gemini RAG Answer
```

## Features

- Conversational RAG with follow-up question support
- Multi-PDF upload in a single session
- Top-K retrieval with similarity threshold filtering
- Source citations with filename and page metadata
- PDF text extraction and chunking
- Gemini embeddings for semantic search
- FastAPI backend API
- Flutter Web chat interface

## How RAG Works

1. Upload one or more PDFs.
2. The backend extracts text and splits it into chunks.
3. Gemini embeddings are generated for each chunk.
4. A question is embedded and compared against all chunks.
5. The top relevant chunks above the similarity threshold are selected.
6. Gemini answers using only the retrieved context.
7. Recent conversation history helps interpret follow-up questions, but the PDF content remains the only source of truth.

## Project Structure

```text
project1-openai-chatbot/
  main.py
  requirements.txt
  .env.example
  README.md
  pdf_rag.py
  chunking.py
  chunked_rag.py
  semantic_search.py
  embeddings.py
  rag.py
  structured_output.py
  memory.json
  voucher.pdf

ai_document_assistant/
  lib/
    main.dart
    models/
    screens/
    services/
    widgets/
  android/
  ios/
  web/
  macos/
  linux/
  windows/
  pubspec.yaml
```

## Tech Stack

- Python
- FastAPI
- pypdf
- NumPy
- google-genai
- Flutter
- Dart
- HTTP multipart upload

## Local Setup

### Backend

```bash
cd project1-openai-chatbot
pip install -r requirements.txt
uvicorn main:app --reload --host 127.0.0.1 --port 8000
```

Create a `.env` file from `.env.example` and set `GEMINI_API_KEY`.

### Flutter Web

```bash
cd ai_document_assistant
flutter pub get
flutter run -d chrome
```

## Production Deployment

### FastAPI Backend

Run the backend behind a production ASGI server and host it on a public HTTPS endpoint.

Recommended deployment steps:

1. Set environment variables in your hosting platform.
2. Install backend dependencies from `requirements.txt`.
3. Launch the app with `uvicorn main:app --host 0.0.0.0 --port 8000`.
4. Set `CORS_ORIGINS` to your deployed Flutter Web domain.
5. Keep `GEMINI_API_KEY` only in backend secrets or environment settings.

### Flutter Web Frontend

Build the frontend for production:

```bash
cd ai_document_assistant
flutter build web
```

Deploy the generated `build/web` folder to a static host.

Before building, make sure the Flutter app points to the production backend URL.

## Environment Variables

Backend only:

- `GEMINI_API_KEY`
- `CORS_ORIGINS`

The Gemini key is never exposed to Flutter.

## API Endpoints

### `GET /`

Health check.

### `POST /upload`

Upload one PDF at a time as multipart form data.

Response:

- `message`
- `filename`
- `pages`
- `chunks`

### `POST /ask`

Request:

```json
{
  "question": "What is the annual leave policy?"
}
```

Response:

- `question`
- `answer`
- `sources`

### `GET /documents`

Returns the list of uploaded PDFs in the current session.

### `POST /clear`

Clears uploaded PDFs, chunks, embeddings, and conversation memory.

## Screenshots

Store the screenshots in `project1-openai-chatbot/assets/screenshots/` and reference them here:

### Upload State
![Upload state](./assets/screenshots/upload-state.png)

### Uploaded Document List
![Uploaded document list](./assets/screenshots/uploaded-document-list.png)

### Chat Conversation With Citations
![Chat conversation with citations](./assets/screenshots/chat-conversation-citations.png)

### Clear/New Document State
![Clear/new document state](./assets/screenshots/clear-new-document-state.png)
