FROM python:3.14-alpine

WORKDIR /app

RUN apk update && apk upgrade --no-cache

COPY requirements.txt .

RUN python -m pip install --no-cache-dir --upgrade pip \
    && python -m pip install --no-cache-dir --upgrade "setuptools==82.0.0" "wheel==0.46.3" "msgpack==1.2.1" \
    && python -m pip install --no-cache-dir -r requirements.txt
COPY app ./app

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]