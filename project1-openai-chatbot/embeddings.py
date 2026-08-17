import os
import numpy as np
from dotenv import load_dotenv
from google import genai

load_dotenv()

client = genai.Client(
    api_key=os.getenv("GEMINI_API_KEY")
)

text1 = "I love programming in Python."
text2 = "Python is my favorite programming language."

response = client.models.embed_content(
    model="gemini-embedding-001",
    contents=[text1, text2]
)

vector1 = np.array(response.embeddings[0].values)
vector2 = np.array(response.embeddings[1].values)

similarity = np.dot(vector1, vector2) / (
    np.linalg.norm(vector1) * np.linalg.norm(vector2)
)

print("Similarity:", similarity)