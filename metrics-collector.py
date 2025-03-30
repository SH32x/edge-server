import requests
import sqlite3
import time

# Function to collect metrics from the Kubernetes API
def collect_metrics():
    api_url = "http://localhost:8080/api/v1/nodes"
    response = requests.get(api_url)
    data = response.json()
    
    metrics = []
    for node in data['items']:
        node_name = node['metadata']['name']
        clock_speed = node['status']['capacity']['cpu']
        memory_use = node['status']['capacity']['memory']
        bandwidth = node['status']['capacity']['pods']
        
        metrics.append((node_name, clock_speed, memory_use, bandwidth))
    
    return metrics

# Function to store metrics in a simple database
def store_metrics(metrics):
    conn = sqlite3.connect('metrics.db')
    cursor = conn.cursor()
    
    cursor.execute('''CREATE TABLE IF NOT EXISTS metrics
                      (node_name TEXT, clock_speed TEXT, memory_use TEXT, bandwidth TEXT)''')
    
    cursor.executemany('INSERT INTO metrics VALUES (?, ?, ?, ?)', metrics)
    
    conn.commit()
    conn.close()

# Main function to collect and store metrics periodically
def main():
    while True:
        metrics = collect_metrics()
        store_metrics(metrics)
        time.sleep(60)  # Collect metrics every 60 seconds

if __name__ == "__main__":
    main()
