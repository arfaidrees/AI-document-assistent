# AI Document Assistant

AI Document Assistant is a full-stack PDF question-answering app built with a FastAPI backend, Gemini, and a Flutter Web frontend.

<<<<<<< HEAD
It supports multi-PDF conversational RAG, source citations, and answers grounded only in the uploaded documents.

## Screenshot Preview

| Upload state | Uploaded document |
| --- | --- |
| ![Upload state](./project1-openai-chatbot/assets/screenshots/upload-state.png) | ![Uploaded document list](./project1-openai-chatbot/assets/screenshots/uploaded-document-list.png) |

| Conversation with citations | Clear/new document state |
| --- | --- |
| ![Chat conversation with citations](./project1-openai-chatbot/assets/screenshots/chat-conversation-citations.png) | ![Clear/new document state](./project1-openai-chatbot/assets/screenshots/clear-new-document-state.png) |

## What It Does

- Upload one or more PDFs in a single session
- Ask follow-up questions in natural language
- Retrieve the most relevant chunks with semantic search
- Answer only from document context
- Show source citations and document metadata

## Screenshots

### Upload State
![Upload state](./project1-openai-chatbot/assets/screenshots/upload-state.png)

### Uploaded Document List
![Uploaded document list](./project1-openai-chatbot/assets/screenshots/uploaded-document-list.png)

### Chat Conversation With Citations
![Chat conversation with citations](./project1-openai-chatbot/assets/screenshots/chat-conversation-citations.png)

### Clear/New Document State
![Clear/new document state](./project1-openai-chatbot/assets/screenshots/clear-new-document-state.png)
=======
It supports multi-PDF conversational RAG, source citations, and PDF-aware answers grounded only in uploaded documents.
>>>>>>> origin/main

## Architecture

```text
<<<<<<< HEAD
Flutter Web
=======
Flutter
>>>>>>> origin/main
  -> FastAPI
  -> PDF Processing
  -> Chunking
  -> Gemini Embeddings
  -> Similarity Search
  -> Gemini RAG Answer
```

<<<<<<< HEAD
=======
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

>>>>>>> origin/main
## Tech Stack

- Python
- FastAPI
- pypdf
- NumPy
- google-genai
- Flutter
- Dart
<<<<<<< HEAD

## Project Structure

```text
project1-openai-chatbot/
  main.py
  requirements.txt
  README.md
  pdf_rag.py
  chunking.py
  chunked_rag.py
  semantic_search.py
  embeddings.py
  rag.py
  structured_output.py
  voucher.pdf

ai_document_assistant/
  lib/
  android/
  ios/
  web/
  macos/
  linux/
  windows/
  pubspec.yaml
```

## Detailed Docs

- Backend and API details: [`project1-openai-chatbot/README.md`](./project1-openai-chatbot/README.md)
- Flutter app: [`ai_document_assistant/README.md`](./ai_document_assistant/README.md)
=======
- HTTP multipart upload
>>>>>>> origin/main

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

<<<<<<< HEAD
## API Summary
=======
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
>>>>>>> origin/main

### `GET /`

Health check.

### `POST /upload`

<<<<<<< HEAD
Upload a PDF as multipart form data.

### `POST /ask`

Ask a question about the uploaded documents.

### `GET /documents`

List uploaded PDFs in the current session.

### `POST /clear`

Clear documents, chunks, embeddings, and conversation memory.

## Notes

- The detailed implementation notes live in the project-specific READMEs.
- Screenshots are stored under `project1-openai-chatbot/assets/screenshots/`.
=======
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
>>>>>>> origin/main
