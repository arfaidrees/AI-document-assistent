# AI Document Assistant

AI Document Assistant is a full-stack PDF question-answering app built with a FastAPI backend, Gemini, and a Flutter Web frontend.

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

## Architecture

```text
Flutter Web
  -> FastAPI
  -> PDF Processing
  -> Chunking
  -> Gemini Embeddings
  -> Similarity Search
  -> Gemini RAG Answer
```

## Tech Stack

- Python
- FastAPI
- pypdf
- NumPy
- google-genai
- Flutter
- Dart

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

## API Summary

### `GET /`

Health check.

### `POST /upload`

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
