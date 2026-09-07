FROM python:3.14-alpine

WORKDIR /app

RUN apk update && apk upgrade --no-cache

COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

COPY app ./app

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]