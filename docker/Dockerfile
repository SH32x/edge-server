FROM python:3.9-slim

# Install dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    make \
    libsm6 \
    libxext6 \
    libxrender-dev \
    && rm -rf /var/lib/apt/lists/*

# Create app directory
WORKDIR /app

# Copy requirements and install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy model and inference script
COPY model/ /app/model/
COPY inference.py /app/

# Expose port for API
EXPOSE 8501

# Run the inference service
CMD ["python", "inference.py"]