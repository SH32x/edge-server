import os
import time
import json
import numpy as np
import psutil
import threading
from flask import Flask, request, jsonify
import tensorflow as tf
from prometheus_client import start_http_server, Gauge, Counter
import requests

app = Flask(__name__)

# Load the TensorFlow Lite model
try:
    # First attempt to use tflite_runtime
    from tflite_runtime.interpreter import Interpreter
    interpreter = Interpreter(model_path="model/model.tflite")
except ImportError:
    # Fall back to TensorFlow if tflite_runtime is not available
    interpreter = tf.lite.Interpreter(model_path="model/model.tflite")

interpreter.allocate_tensors()

# Get input and output tensors
input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()

# Print model details
print(f"Model loaded successfully")
print(f"Input details: {input_details}")
print(f"Output details: {output_details}")

# Set up Prometheus metrics
CLOCK_SPEED = Gauge("node_cpu_frequency_mhz", "CPU frequency in MHz")
MEMORY_USAGE = Gauge("process_memory_usage_mb", "Memory usage in MB")
BANDWIDTH = Counter("network_bandwidth_bytes", "Network bandwidth usage in bytes")
INFERENCE_COUNT = Counter("inference_count_total", "Total number of inferences")
INFERENCE_TIME = Gauge("inference_time_ms", "Time taken for inference in ms")

# Get node name from environment variable
NODE_NAME = os.environ.get("NODE_NAME", "unknown")

# Metrics collection function
def collect_metrics():
    while True:
        # CPU frequency
        cpu_freq = psutil.cpu_freq()
        if cpu_freq:
            CLOCK_SPEED.set(cpu_freq.current)
        
        # Memory usage
        process = psutil.Process(os.getpid())
        memory_info = process.memory_info()
        MEMORY_USAGE.set(memory_info.rss / (1024 * 1024))  # Convert to MB
        
        # Export metrics to InfluxDB
        try:
            metrics = {
                "measurement": "edge_metrics",
                "tags": {
                    "node": NODE_NAME
                },
                "fields": {
                    "cpu_mhz": cpu_freq.current if cpu_freq else 0,
                    "memory_mb": memory_info.rss / (1024 * 1024),
                    "inference_count": INFERENCE_COUNT._value.get(),
                }
            }
            
            # This would typically go to InfluxDB, but for simplicity we just log it
            print(f"Metrics: {metrics}")
            
        except Exception as e:
            print(f"Error exporting metrics: {e}")
        
        time.sleep(15)  # Collect every 15 seconds

# Start metrics collection in background thread
metrics_thread = threading.Thread(target=collect_metrics, daemon=True)
metrics_thread.start()

# Start Prometheus metrics server
start_http_server(8000)

@app.route('/predict', methods=['POST'])
def predict():
    start_time = time.time()
    
    try:
        # Get the input data from the request
        request_size = request.content_length or 0
        BANDWIDTH.inc(request_size)
        
        data = request.get_json(force=True)
        input_data = np.array(data['input'], dtype=np.float32)
        
        # Reshape input data to match model's expected shape
        if len(input_data.shape) == 1:
            # Reshape for batch size 1 if needed
            expected_shape = input_details[0]['shape']
            if len(expected_shape) > 1:
                if expected_shape[0] == 1:  # Batch dimension is 1
                    input_data = input_data.reshape(tuple(expected_shape[1:]))
                else:
                    input_data = input_data.reshape((1,) + tuple(input_data.shape))
        
        # Set the input tensor
        interpreter.set_tensor(input_details[0]['index'], input_data)
        
        # Run inference
        interpreter.invoke()
        
        # Get the output tensor
        output_data = interpreter.get_tensor(output_details[0]['index'])
        
        # Update metrics
        INFERENCE_COUNT.inc()
        inference_time = (time.time() - start_time) * 1000  # Convert to ms
        INFERENCE_TIME.set(inference_time)
        
        # Prepare and send response
        result = {"prediction": output_data.tolist()}
        response = jsonify(result)
        
        # Estimate response size and update bandwidth metric
        response_size = len(json.dumps(result).encode())
        BANDWIDTH.inc(response_size)
        
        return response
        
    except Exception as e:
        error_msg = {"error": str(e)}
        return jsonify(error_msg), 500

@app.route('/health', methods=['GET'])
def health():
    return jsonify({"status": "healthy"})

@app.route('/metrics', methods=['GET'])
def metrics():
    # This is redundant as Prometheus metrics are served on port 8000,
    # but it's a useful endpoint for debugging
    metrics = {
        "clock_speed_mhz": psutil.cpu_freq().current if psutil.cpu_freq() else 0,
        "memory_usage_mb": psutil.Process(os.getpid()).memory_info().rss / (1024 * 1024),
        "inference_count": INFERENCE_COUNT._value.get(),
        "inference_time_ms": INFERENCE_TIME._value.get()
    }
    return jsonify(metrics)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8501)