import os
from dotenv import load_dotenv
from google import genai
from pydantic import BaseModel

load_dotenv()

client = genai.Client(
    api_key=os.getenv("GEMINI_API_KEY")
)


class PythonExplanation(BaseModel):
    topic: str
    difficulty: str
    summary: str
    keywords: list[str]


prompt = """
Explain Python to a beginner.
"""


response = client.models.generate_content(
    model="gemini-3.5-flash",
    contents=prompt,
    config={
        "response_mime_type": "application/json",
        "response_schema": PythonExplanation,
    },
)

result = response.parsed

print("Topic:", result.topic)
print("Difficulty:", result.difficulty)
print("Summary:", result.summary)
print("Keywords:", result.keywords)