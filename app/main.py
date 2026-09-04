import os
import psycopg
from dotenv import load_dotenv

from fastapi import FastAPI
from pydantic import BaseModel



load_dotenv()


DATABASE_URL = os.getenv("DATABASE_URL")
def get_db_connection():
    return psycopg.connect(DATABASE_URL)



class Task(BaseModel):
    title: str
    done: bool = False


app = FastAPI()


tasks = [
    {"id": 1, "title": "Learn Docker", "done": False},
    {"id": 2, "title": "Deploy to AWS", "done": False}
]


@app.get("/health")
def health_check():
    return {"status": "healthy"}


@app.get("/tasks")
def get_tasks():
    with get_db_connection() as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT id, title, done FROM tasks;")
            rows = cur.fetchall()

    return rows


@app.post("/tasks")
def create_task(task: Task):
    with get_db_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                INSERT INTO tasks (title, done)
                VALUES (%s, %s)
                RETURNING id, title, done;
                """,
                (task.title, task.done)
            )

            new_task = cur.fetchone()

    return new_task