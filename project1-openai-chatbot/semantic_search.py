import os
import numpy as np
from dotenv import load_dotenv
from google import genai

load_dotenv()

client = genai.Client(
    api_key=os.getenv("GEMINI_API_KEY")
)

# Our knowledge base
documents = [
    "Employees receive 30 days of annual leave every year.",
    "Employees can work remotely two days per week.",
    "Medical expenses can be reimbursed according to company policy.",
    "The company provides transportation allowance to eligible employees.",
]

# User's question
query = "How many vacation days do employees get?"


# Create embeddings for all documents
document_response = client.models.embed_content(
    model="gemini-embedding-001",
    contents=documents
)

# Create embedding for the user's question
query_response = client.models.embed_content(
    model="gemini-embedding-001",
    contents=query
)

query_vector = np.array(query_response.embeddings[0].values)


# Calculate similarity
results = []

for i, embedding in enumerate(document_response.embeddings):

    document_vector = np.array(embedding.values)

    similarity = np.dot(query_vector, document_vector) / (
        np.linalg.norm(query_vector)
        * np.linalg.norm(document_vector)
    )

    results.append((similarity, documents[i]))


# Sort from most similar to least similar
results.sort(reverse=True)


print("\n🔎 Search results:\n")

for score, document in results:
    print(f"Score: {score:.4f}")
    print(f"Document: {document}")
    print()