import os
import numpy as np
from pypdf import PdfReader
from dotenv import load_dotenv
from google import genai

load_dotenv()

client = genai.Client(
    api_key=os.getenv("GEMINI_API_KEY")
)


# --------------------------------
# 1. Load PDF
# --------------------------------

PDF_FILE = "voucher.pdf"

reader = PdfReader(PDF_FILE)

text = ""

for page in reader.pages:
    page_text = page.extract_text()

    if page_text:
        text += page_text + "\n"

print(f"📄 PDF loaded: {len(reader.pages)} pages")


# --------------------------------
# 2. Split PDF text into chunks
# --------------------------------

def chunk_text(text, sentences_per_chunk=3):

    sentences = [
        sentence.strip()
        for sentence in text.split(".")
        if sentence.strip()
    ]

    chunks = []

    for i in range(
        0,
        len(sentences),
        sentences_per_chunk
    ):

        chunk = ". ".join(
            sentences[i:i + sentences_per_chunk]
        ) + "."

        chunks.append(chunk)

    return chunks


chunks = chunk_text(text)

print(f"📚 Created {len(chunks)} chunks")


# --------------------------------
# 3. Create embeddings
# --------------------------------

embedding_response = client.models.embed_content(
    model="gemini-embedding-001",
    contents=chunks
)


# --------------------------------
# 4. Ask question
# --------------------------------

query = input("\nAsk a question about the PDF: ")


# --------------------------------
# 5. Embed question
# --------------------------------

query_response = client.models.embed_content(
    model="gemini-embedding-001",
    contents=query
)

query_vector = np.array(
    query_response.embeddings[0].values
)


# --------------------------------
# 6. Search chunks
# --------------------------------

results = []

for i, embedding in enumerate(
    embedding_response.embeddings
):

    chunk_vector = np.array(
        embedding.values
    )

    similarity = np.dot(
        query_vector,
        chunk_vector
    ) / (
        np.linalg.norm(query_vector)
        * np.linalg.norm(chunk_vector)
    )

    results.append(
        (similarity, chunks[i])
    )


# Highest similarity first
results.sort(reverse=True)


# --------------------------------
# 7. Retrieve top 3 chunks
# --------------------------------

top_chunks = results[:3]


print("\n🔎 Retrieved information:\n")

for score, chunk in top_chunks:

    print(f"Score: {score:.4f}")
    print(f"Chunk: {chunk}\n")


# --------------------------------
# 8. Build context
# --------------------------------

context = "\n".join(
    chunk for score, chunk in top_chunks
)


# --------------------------------
# 9. Ask Gemini
# --------------------------------

prompt = f"""
You are a document question-answering assistant.

Answer the user's question using ONLY the
information provided in the context.

Do not make up information.

If the answer is not available in the context,
say:

"I don't have enough information in the document
to answer that."

Context:
{context}

Question:
{query}
"""


response = client.models.generate_content(
    model="gemini-3.5-flash",
    contents=prompt
)


# --------------------------------
# 10. Final answer
# --------------------------------

print("🤖 AI Answer:")
print(response.text)