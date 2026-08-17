import os
import json

from dotenv import load_dotenv
from google import genai

load_dotenv()

client = genai.Client(
    api_key=os.getenv("GEMINI_API_KEY")
)

MEMORY_FILE = "memory.json"


def load_memory():
    if os.path.exists(MEMORY_FILE):
        with open(MEMORY_FILE, "r") as file:
            return json.load(file)

    return []


def save_memory(history):
    with open(MEMORY_FILE, "w") as file:
        json.dump(history, file, indent=2)


print("🤖 AI Chatbot started!")
print("Type 'exit' to quit.\n")

chat_history = load_memory()

while True:
    user_message = input("You: ")

    if user_message.lower() == "exit":
        save_memory(chat_history)
        print("Memory saved. Goodbye!")
        break

    chat_history.append({
        "role": "user",
        "parts": [{"text": user_message}]
    })

    response = client.models.generate_content(
        model="gemini-3.5-flash",
        contents=chat_history,
        config={
            "system_instruction": """
You are a helpful AI assistant.

Explain concepts clearly and simply.
When teaching programming, provide practical examples.
Remember important information from the conversation.
"""
        }
    )

    ai_message = response.text

    print(f"\nAI: {ai_message}\n")

    chat_history.append({
        "role": "model",
        "parts": [{"text": ai_message}]
    })

    save_memory(chat_history)