# app/src/main.py
from fastapi import FastAPI
app = FastAPI()
@app.get("/healthz")
def healthz(): return {"status": "ok"}
@app.get("/")
def root(): return {"message": "hello from secure container lab"}
