# Solution Dockerfile for Lab 2
# This is a basic, working Dockerfile for the Flask app

FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Copy dependencies first (for layer caching)
COPY requirements.txt .

# Install dependencies
# --no-cache-dir reduces image size by not caching pip packages
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY app.py .

# Document the port (doesn't actually expose it)
EXPOSE 5000

# Default command to run
CMD ["python", "app.py"]
