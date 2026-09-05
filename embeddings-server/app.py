from fastapi import FastAPI
from pydantic import BaseModel
from sentence_transformers import SentenceTransformer
from typing import List, Union

app = FastAPI()
model = SentenceTransformer("BAAI/bge-m3", device="cpu")


class EmbedRequest(BaseModel):
    inputs: Union[str, List[str]]


@app.post("/embed")
def embed(req: EmbedRequest):
    texts = [req.inputs] if isinstance(req.inputs, str) else req.inputs
    vectors = model.encode(texts, normalize_embeddings=True)
    return vectors.tolist()


@app.get("/health")
def health():
    return {"status": "ok"}
