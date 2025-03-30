# Use a base image with Python and Tensorflow Lite for Microcontrollers
FROM python:3.8-slim

# Set the working directory
WORKDIR /app

# Install Tensorflow Lite for Microcontrollers
RUN pip install tflite-runtime

# Copy the neural network model file into the image
COPY model.tflite /app/model.tflite

# Set the entrypoint to run the inference script
ENTRYPOINT ["python", "inference.py"]
