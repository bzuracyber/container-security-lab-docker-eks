# app/Dockerfile
FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1

# Create app user
RUN addgroup --system app && adduser --system --ingroup app app

WORKDIR /app

# Upgrade pip + setuptools to patched versions
RUN pip install --upgrade pip setuptools

# Install dependencies
COPY src/requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Copy app code
COPY src/ /app/

USER app
EXPOSE 8000

CMD ["python", "-m", "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]