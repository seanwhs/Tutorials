# RAG Example Skeleton (Python)

# 1. Retrieve relevant documents
def retrieve(query):
    # mock vector DB query
    return ["Document 1", "Document 2"]

# 2. Augment query
def augment_query(query):
    docs = retrieve(query)
    return f"{query}\nContext: {docs}"

# 3. Feed into LLM
def generate_answer(query):
    augmented = augment_query(query)
    # Mock LLM response
    return f"Answer based on: {augmented}"

print(generate_answer("What is the total revenue?"))
