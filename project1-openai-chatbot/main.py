import os
import re
import shutil
from pathlib import Path
from typing import List

import numpy as np
from dotenv import load_dotenv
from fastapi import FastAPI, File, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from google import genai
from google.genai import errors as genai_errors
from pydantic import BaseModel
from pypdf import PdfReader

load_dotenv()

api_key = os.getenv("GEMINI_API_KEY")
if not api_key:
    raise RuntimeError("GEMINI_API_KEY is not set in the environment.")

client = genai.Client(api_key=api_key)

app = FastAPI(title="AI Document Assistant API")


def parse_csv_env(value: str | None, fallback: list[str]) -> list[str]:
    if not value:
        return fallback
    items = [item.strip() for item in value.split(",")]
    return [item for item in items if item]


cors_origins = parse_csv_env(
    os.getenv("CORS_ORIGINS"),
    [
        "http://localhost:3000",
        "http://localhost:5000",
        "http://localhost:5173",
        "http://localhost:8000",
        "http://127.0.0.1:3000",
        "http://127.0.0.1:5000",
        "http://127.0.0.1:5173",
        "http://127.0.0.1:8000",
    ],
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=cors_origins,
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)


class QuestionRequest(BaseModel):
    question: str


document_state = {
    "documents": [],
    "conversation_history": [],
}

TOP_K = 3
SIMILARITY_THRESHOLD = 0.50
HISTORY_TURNS = 4
UPLOAD_PATH = Path("uploaded_document.pdf")


def chunk_text(text: str, sentences_per_chunk: int = 3) -> List[str]:
    text = re.sub(r"\s+", " ", text).strip()
    if not text:
        return []

    sentences = re.split(r"(?<=[.!?])\s+", text)
    sentences = [sentence.strip() for sentence in sentences if sentence.strip()]

    chunks = []
    for i in range(0, len(sentences), sentences_per_chunk):
        chunk = " ".join(sentences[i : i + sentences_per_chunk]).strip()
        if chunk:
            chunks.append(chunk)

    if not chunks and text:
        chunks.append(text)

    return chunks


def cosine_similarity(vec_a: np.ndarray, vec_b: np.ndarray) -> float:
    denom = np.linalg.norm(vec_a) * np.linalg.norm(vec_b)
    if denom == 0:
        return 0.0
    return float(np.dot(vec_a, vec_b) / denom)


def extract_pdf_text(reader: PdfReader) -> str:
    pages_text = []
    for page in reader.pages:
        page_text = page.extract_text()
        if page_text:
            pages_text.append(page_text)
    return "\n".join(pages_text).strip()


def reset_document_state():
    document_state["documents"] = []
    document_state["conversation_history"] = []


def is_follow_up_question(question: str) -> bool:
    lowered = question.lower().strip()
    followup_markers = (
        "what about",
        "what else",
        "same",
        "also",
        "and then",
        "previous",
        "earlier",
        "follow up",
        "follow-up",
    )
    starts_like_followup = lowered.startswith(
        ("what about", "and what about", "what else", "also", "and ")
    )
    pronoun_fragment = lowered in {"that", "it", "those", "this", "they", "them", "same"}
    return starts_like_followup or pronoun_fragment or any(
        marker in lowered for marker in followup_markers
    )


def build_retrieval_query(question: str) -> str:
    if not is_follow_up_question(question):
        return question

    history = document_state["conversation_history"][-HISTORY_TURNS:]
    if not history:
        return question

    lines = []
    for turn in history:
        role = turn.get("role", "user").capitalize()
        content = turn.get("content", "").strip()
        if content:
            lines.append(f"{role}: {content}")

    lines.append(f"User: {question}")
    return "\n".join(lines)


def build_sources_and_context(question: str):
    retrieval_query = build_retrieval_query(question)
    query_response = client.models.embed_content(
        model="gemini-embedding-001",
        contents=retrieval_query,
    )
    query_vector = np.array(query_response.embeddings[0].values, dtype=np.float32)

    scored_chunks = []
    for index, entry in enumerate(document_state["documents"]):
        chunk = entry["text"]
        embedding = entry["embedding"]
        similarity = cosine_similarity(query_vector, embedding)
        scored_chunks.append(
            {
                "chunk": index,
                "chunk_index": entry["chunk_index"],
                "score": similarity,
                "text": chunk,
                "filename": entry["filename"],
                "page": entry["page"],
            }
        )

    scored_chunks.sort(key=lambda item: item["score"], reverse=True)
    top_chunks = scored_chunks[:TOP_K]
    relevant_sources = [
        source for source in top_chunks if source["score"] >= SIMILARITY_THRESHOLD
    ]

    context_parts = []
    for position, source in enumerate(relevant_sources, start=1):
        header = f"[Source {position}] {source['filename']}"
        if source["page"] is not None:
            header += f" | page {source['page']}"
        context_parts.append(f"{header}\n{source['text']}")

    context = "\n\n".join(context_parts)
    return relevant_sources, context, retrieval_query != question


def append_history(question: str, answer: str) -> None:
    document_state["conversation_history"].append({"role": "user", "content": question})
    document_state["conversation_history"].append({"role": "assistant", "content": answer})


def document_missing_message() -> str:
    return "The document does not contain enough relevant information to answer that."


@app.get("/")
def home():
    return {"message": "AI Document Assistant API is running!"}


@app.post("/upload")
async def upload_pdf(file: UploadFile = File(...)):
    if not file.filename.lower().endswith(".pdf"):
        raise HTTPException(status_code=400, detail="Only PDF files are supported.")

    file_path = UPLOAD_PATH
    try:
        with open(file_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)

        reader = PdfReader(file_path)
        text = extract_pdf_text(reader)
        if not text:
            raise HTTPException(status_code=400, detail="Could not extract text from PDF.")

        chunks = chunk_text(text)
        if not chunks:
            raise HTTPException(
                status_code=400, detail="Could not create chunks from PDF text."
            )

        try:
            embedding_response = client.models.embed_content(
                model="gemini-embedding-001",
                contents=chunks,
            )
        except genai_errors.APIError as exc:
            raise HTTPException(
                status_code=502,
                detail=f"Gemini embedding request failed: {exc}",
            ) from exc

        embeddings = [
            np.array(embedding.values, dtype=np.float32)
            for embedding in embedding_response.embeddings
        ]

        start_chunk_index = len(document_state["documents"])
        for local_index, (chunk, embedding) in enumerate(zip(chunks, embeddings)):
            page_number = None
            if len(reader.pages) > 0:
                pages_per_chunk = max(1, len(reader.pages) // max(1, len(chunks)))
                page_number = min(len(reader.pages), (local_index * pages_per_chunk) + 1)
            document_state["documents"].append(
                {
                    "id": f"{file.filename}:{start_chunk_index + local_index}",
                    "filename": file.filename,
                    "page": page_number,
                    "chunk_index": local_index,
                    "text": chunk,
                    "embedding": embedding,
                }
            )

        return {
            "message": "PDF uploaded successfully.",
            "filename": file.filename,
            "pages": len(reader.pages),
            "chunks": len(chunks),
        }
    except HTTPException:
        raise
    except genai_errors.APIError as exc:
        raise HTTPException(status_code=502, detail=f"Gemini upload processing failed: {exc}") from exc
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"Upload failed: {exc}") from exc
    finally:
        try:
            if file_path.exists():
                file_path.unlink()
        except Exception:
            pass


@app.get("/documents")
def list_documents():
    documents = []
    seen = set()
    for entry in document_state["documents"]:
        key = entry["filename"]
        if key in seen:
            continue
        seen.add(key)
        documents.append({"filename": entry["filename"]})
    return {"documents": documents}


@app.post("/ask")
async def ask_question(request: QuestionRequest):
    question = request.question.strip()
    if not question:
        raise HTTPException(status_code=400, detail="Question cannot be empty.")

    if not document_state["documents"]:
        raise HTTPException(status_code=400, detail="Please upload a PDF first.")

    sources, context, used_history = build_sources_and_context(question)
    if not sources:
        answer = document_missing_message()
        append_history(question, answer)
        return {"question": question, "answer": answer, "sources": []}

    if used_history:
        history_lines = []
        for turn in document_state["conversation_history"][-HISTORY_TURNS:]:
            role = turn.get("role", "user").capitalize()
            content = turn.get("content", "").strip()
            if content:
                history_lines.append(f"{role}: {content}")
        conversation_context = (
            "\n".join(history_lines) if history_lines else "No prior conversation."
        )
    else:
        conversation_context = "No prior conversation."

    prompt = f"""
You are an AI document assistant.

Answer the user's question using ONLY the supplied document context.
Do not invent facts.
If the context does not contain the answer, say that the document does not contain enough information.
Do not mention internal similarity scores unless asked.

Rules:
- Use only the context below.
- Keep the answer concise and factual.
- Use the conversation history only to understand follow-up references like "that", "it", or "those".
- Never use the conversation history as a source of facts.
- If the answer is not directly supported by the document context, say the document does not contain enough information.

Conversation history:
{conversation_context}

Document context:
{context}

Question:
{question}
""".strip()

    try:
        response = client.models.generate_content(
            model="gemini-3.5-flash",
            contents=prompt,
        )
        answer = (response.text or "").strip()
    except genai_errors.APIError as exc:
        raise HTTPException(status_code=502, detail=f"Gemini answer generation failed: {exc}") from exc
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"Answer generation failed: {exc}") from exc

    if not answer:
        answer = document_missing_message()

    append_history(question, answer)
    return {"question": question, "answer": answer, "sources": sources}


@app.post("/clear")
def clear_session():
    reset_document_state()
    return {"message": "Document and conversation cleared."}
