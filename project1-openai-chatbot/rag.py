import os
import numpy as np
from dotenv import load_dotenv
from google import genai

load_dotenv()

client = genai.Client(
    api_key=os.getenv("GEMINI_API_KEY")
)

# -----------------------------
# 1. Our knowledge base
# -----------------------------

documents = [
    "Employees receive 30 days of annual leave every year.",
    "Employees can work remotely two days per week.",
    "Medical expenses can be reimbursed according to company policy.",
    "The company provides transportation allowance to eligible employees.",
]


# -----------------------------
# 2. User question
# -----------------------------

query = "How many vacation days do employees get?"


# -----------------------------
# 3. Create document embeddings
# -----------------------------

document_response = client.models.embed_content(
    model="gemini-embedding-001",
    contents=documents
)


# -----------------------------
# 4. Create question embedding
# -----------------------------

query_response = client.models.embed_content(
    model="gemini-embedding-001",
    contents=query
)

query_vector = np.array(
    query_response.embeddings[0].values
)


# -----------------------------
# 5. Find most relevant document
# -----------------------------

results = []

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

# Take the best result
best_score, best_document = results[0]


print("\n🔎 Retrieved document:")
print(best_document)

print(f"\nSimilarity score: {best_score:.4f}")


# -----------------------------
# 6. Give retrieved information
#    to Gemini
# -----------------------------

prompt = f"""
Answer the user's question using ONLY the information
provided in the context below.

Context:
{best_document}

User question:
{query}

If the context does not contain the answer, say:
"I don't have enough information to answer that."
"""


response = client.models.generate_content(
    model="gemini-3.5-flash",
    contents=prompt
)


# -----------------------------
# 7. Final answer
# -----------------------------

print("\n🤖 AI Answer:")
print(response.text)