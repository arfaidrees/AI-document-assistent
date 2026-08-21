import os
import numpy as np
from dotenv import load_dotenv
from google import genai

load_dotenv()

client = genai.Client(
    api_key=os.getenv("GEMINI_API_KEY")
)

# -----------------------------
# Knowledge base
# -----------------------------

documents = [
    "Employees receive 30 days of annual leave every year.",
    "Employees can work remotely two days per week.",
    "Medical expenses can be reimbursed according to company policy.",
    "The company provides transportation allowance to eligible employees.",
    "Employees receive their salary at the end of each month.",
]


# -----------------------------
# Create embeddings
# -----------------------------

document_response = client.models.embed_content(
    model="gemini-embedding-001",
    contents=documents
)


def retrieve_documents(query, top_k=2):

    # Embed the user's question
    query_response = client.models.embed_content(
        model="gemini-embedding-001",
        contents=query
    )

    query_vector = np.array(
        query_response.embeddings[0].values
    )

    results = []

    # Compare question with every document
    for i, embedding in enumerate(document_response.embeddings):

        document_vector = np.array(
            embedding.values
        )

        similarity = np.dot(
            query_vector,
            document_vector
        ) / (
            np.linalg.norm(query_vector)
            * np.linalg.norm(document_vector)
        )

        results.append(
            (similarity, documents[i])
        )

    # Highest similarity first
    results.sort(reverse=True)

    return results[:top_k]


# -----------------------------
# Ask a question
# -----------------------------

query = input("Ask a question: ")

results = retrieve_documents(query)


# -----------------------------
# Show retrieved documents
# -----------------------------

print("\n🔎 Retrieved information:\n")

for score, document in results:
    print(f"Score: {score:.4f}")
    print(f"Document: {document}\n")


# -----------------------------
# Build context
# -----------------------------

context = "\n".join(
    document for score, document in results
)


# -----------------------------
# Ask Gemini
# -----------------------------

prompt = f"""
You are a helpful company policy assistant.

Answer the user's question using ONLY the information
provided in the context.

If the answer is not contained in the context,
say: "I don't have enough information to answer that."

Context:
{context}

Question:
{query}
"""


response = client.models.generate_content(
    model="gemini-3.5-flash",
    contents=prompt
)


print("🤖 AI Answer:")
print(response.text)