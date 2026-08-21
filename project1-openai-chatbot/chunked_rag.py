import os
import numpy as np
from dotenv import load_dotenv
from google import genai

load_dotenv()

client = genai.Client(
    api_key=os.getenv("GEMINI_API_KEY")
)


# --------------------------------
# 1. Original document
# --------------------------------

document = """
Employees are entitled to 30 days of annual leave every year.
Employees must submit leave requests through the employee portal.
Managers are responsible for approving or rejecting leave requests.
Unused annual leave is handled according to company policy.
Medical leave requires appropriate supporting documentation.
Maternity leave is provided according to applicable company policy.
"""


# --------------------------------
# 2. Chunk the document
# --------------------------------

def chunk_text(text, sentences_per_chunk=2):

    sentences = [
        sentence.strip()
        for sentence in text.split(".")
        if sentence.strip()
    ]

    chunks = []

    for i in range(0, len(sentences), sentences_per_chunk):

        chunk = ". ".join(
            sentences[i:i + sentences_per_chunk]
        ) + "."

        chunks.append(chunk)

    return chunks


chunks = chunk_text(document)

print(f"📄 Created {len(chunks)} chunks.")


# --------------------------------
# 3. Create embeddings for chunks
# --------------------------------

embedding_response = client.models.embed_content(
    model="gemini-embedding-001",
    contents=chunks
)


# --------------------------------
# 4. Ask the user a question
# --------------------------------

query = input("\nAsk a question: ")


# --------------------------------
# 5. Create embedding for question
# --------------------------------

query_response = client.models.embed_content(
    model="gemini-embedding-001",
    contents=query
)

query_vector = np.array(
    query_response.embeddings[0].values
)


# --------------------------------
# 6. Find similarity
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


# --------------------------------
# 7. Sort by similarity
# --------------------------------

results.sort(reverse=True)


# --------------------------------
# 8. Retrieve top 2 chunks
# --------------------------------

top_chunks = results[:2]


print("\n🔎 Retrieved information:\n")

for score, chunk in top_chunks:

    print(f"Score: {score:.4f}")
    print(f"Chunk: {chunk}\n")


# --------------------------------
# 9. Build context
# --------------------------------

context = "\n".join(
    chunk for score, chunk in top_chunks
)


# --------------------------------
# 10. Send context + question
#     to Gemini
# --------------------------------

prompt = f"""
You are a company policy assistant.

Answer the user's question using ONLY the information
provided in the context.

Do not make up information.

If the answer is not available in the context,
say:

"I don't have enough information to answer that."

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
# 11. Final answer
# --------------------------------

print("🤖 AI Answer:")
print(response.text)