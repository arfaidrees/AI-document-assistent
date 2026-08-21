def chunk_text(text, sentences_per_chunk=2):
    sentences = [
        sentence.strip()
        for sentence in text.split(".")
        if sentence.strip()
    ]

    chunks = []

    for i in range(0, len(sentences), sentences_per_chunk):
        chunk = ". ".join(sentences[i:i + sentences_per_chunk]) + "."
        chunks.append(chunk)

    return chunks


document = """
Employees are entitled to 30 days of annual leave every year.
Employees must submit leave requests through the employee portal.
Managers are responsible for approving or rejecting leave requests.
Unused annual leave is handled according to company policy.
Medical leave requires appropriate supporting documentation.
Maternity leave is provided according to applicable company policy.
"""


chunks = chunk_text(document)


print("Number of chunks:", len(chunks))

for i, chunk in enumerate(chunks):
    print(f"\n--- Chunk {i + 1} ---")
    print(chunk)