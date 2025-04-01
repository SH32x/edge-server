import os
import time
import json
import numpy as np
import psutil
import threading
from flask import Flask, request, jsonify
import requests
from prometheus_client import start_http_server, Gauge, Counter

app = Flask(__name__)


class Model:
    def __init__(self):
        self.weights = np.array([0.1, 0.2, 0.3, 0.4])
        print("Inference model")

    def predict(self, input_data):
        # weighted sum
        if len(input_data.shape) == 1:
            return np.sum(input_data * self.weights)
        else:
            return np.sum(input_data * self.weights, axis=1)


model = Model()


CLOCK_SPEED = Gauge("node_cpu_frequency_mhz", "CPU frequency (MHz)")
MEMORY_USAGE = Gauge("process_memory_usage_mb", "Memory usage (MB)")
BANDWIDTH = Counter("network_bandwidth_bytes", "Network bandwidth usage (bytes)")
INFERENCE_COUNT = Counter("inference_count_total", "Total number of inferences")
INFERENCE_TIME = Gauge("inference_time_ms", "Inference time (ms)")

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
        MEMORY_USAGE.set(memory_info.rss / (1024 * 1024))

        try:
            metrics = {
                "measurement": "edge_metrics",
                "tags": {"node": NODE_NAME},
                "fields": {
                    "cpu_mhz": cpu_freq.current if cpu_freq else 0,
                    "memory_mb": memory_info.rss / (1024 * 1024),
                    "inference_count": INFERENCE_COUNT._value.get(),
                },
            }

            print(f"Metrics: {metrics}")

        except Exception as e:
            print(f"Error exporting metrics: {e}")

        time.sleep(15)


metrics_thread = threading.Thread(target=collect_metrics, daemon=True)
metrics_thread.start()

# Start Prometheus metrics server
try:
    start_http_server(8000)
    print("Prometheus metrics server started on port 8000")
except Exception as e:
    print(f"Prometheus server failed to load: {e}")


@app.route("/predict", methods=["POST"])
def predict():
    start_time = time.time()

    try:

        request_size = request.content_length or 0
        BANDWIDTH.inc(request_size)

        data = request.get_json(force=True)
        input_data = np.array(data["input"], dtype=np.float32)

        output_data = model.predict(input_data)

        INFERENCE_COUNT.inc()
        inference_time = (time.time() - start_time) * 1000  # ms
        INFERENCE_TIME.set(inference_time)

        result = {"prediction": float(output_data)}
        response = jsonify(result)

        response_size = len(json.dumps(result).encode())
        BANDWIDTH.inc(response_size)

        return response

    except Exception as e:
        error_msg = {"error": str(e)}
        return jsonify(error_msg), 500


@app.route("/health", methods=["GET"])
def health():
    return jsonify({"status": "healthy"})


@app.route("/metrics", methods=["GET"])
def metrics():

    metrics = {
        "clock_speed_mhz": psutil.cpu_freq().current if psutil.cpu_freq() else 0,
        "memory_usage_mb": psutil.Process(os.getpid()).memory_info().rss
        / (1024 * 1024),
        "inference_count": INFERENCE_COUNT._value.get(),
        "inference_time_ms": INFERENCE_TIME._value.get(),
    }
    return jsonify(metrics)


@app.route("/", methods=["GET"])
def home():
    return """
    <html>
        <head><title>Edge ML Server</title></head>
        <body>
            <h1>Edge ML Server</h1>
            <p>These are the server endpoints:</p>
            <ul>
                <li><a href="/health">Health</a></li>
                <li><a href="/metrics">Metrics</a></li>
                <li>POST to /predict with JSON {"input": [1.0, 2.0, 3.0, 4.0]}</li>
            </ul>
        </body>
    </html>
    """


if __name__ == "__main__":
    print("Starting Flask application on port 8501")
    app.run(host="0.0.0.0", port=8501)
