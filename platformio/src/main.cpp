#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <chrono>
#include <thread>
#include <random>

// Only include ArduinoJson when on Windows
#ifdef WINDOWS
#include <ArduinoJson.h>
#endif

// Mock ESP class for Windows
#ifdef WINDOWS
class ESP
{
public:
  static int getFreeHeap() { return 200000; }
};
#endif

// Simple model class to simulate inference
class SimpleModel
{
private:
  float weights[4] = {0.1f, 0.2f, 0.3f, 0.4f};

public:
  SimpleModel()
  {
    std::cout << "Edge ML Inference Simulator - TensorFlow Lite Mock" << std::endl;
    std::cout << "Model loaded successfully" << std::endl;
  }

  float predict(const float *input, size_t size)
  {
    float sum = 0.0f;
    for (size_t i = 0; i < size && i < 4; i++)
    {
      sum += input[i] * weights[i];
    }
    return sum;
  }
};

// Global variables
SimpleModel *model = nullptr;
unsigned long inference_count = 0;
unsigned long total_inference_time = 0;
unsigned long max_inference_time = 0;

void setup()
{
  std::cout << "TensorFlow Lite Microcontroller Inference Simulator Starting..." << std::endl;

  // Initialize model
  model = new SimpleModel();

  std::cout << "TensorFlow Lite Microcontroller Inference Simulator Ready!" << std::endl;
  std::cout << "Enter JSON in the format: {\"input\": [1.0, 2.0, 3.0, 4.0]}" << std::endl;
}

void loop()
{
  std::string line;
  std::cout << "> ";
  if (std::getline(std::cin, line))
  {
    if (line.empty())
    {
      return;
    }

// Parse JSON input
#ifdef WINDOWS
    DynamicJsonDocument doc(1024);
    DeserializationError error = deserializeJson(doc, line);

    if (error)
    {
      std::cout << "Error parsing JSON: " << error.c_str() << std::endl;
      return;
    }

    // Extract input data
    if (!doc.containsKey("input") || !doc["input"].is<JsonArray>())
    {
      std::cout << "Invalid input format. Expected: {\"input\": [values]}" << std::endl;
      return;
    }

    // Get input values
    JsonArray input_array = doc["input"];
    std::vector<float> input;
    for (JsonVariant value : input_array)
    {
      input.push_back(value.as<float>());
    }
#else
    // Simple non-ArduinoJson parsing for non-Windows platforms
    std::vector<float> input = {1.0f, 2.0f, 3.0f, 4.0f};
#endif

    // Perform inference
    auto start_time = std::chrono::high_resolution_clock::now();
    float output = model->predict(input.data(), input.size());
    auto end_time = std::chrono::high_resolution_clock::now();

    // Calculate inference time in milliseconds
    auto inference_time = std::chrono::duration_cast<std::chrono::milliseconds>(end_time - start_time).count();

    // Update metrics
    inference_count++;
    total_inference_time += inference_time;
    max_inference_time = std::max(max_inference_time, (unsigned long)inference_time);

// Output result in JSON format
#ifdef WINDOWS
    DynamicJsonDocument result_doc(1024);
    result_doc["status"] = "success";
    result_doc["inference_time_ms"] = inference_time;
    result_doc["output"] = output;

    std::string result;
    serializeJson(result_doc, result);
    std::cout << result << std::endl;
#else
    std::cout << "{\"status\":\"success\",\"inference_time_ms\":" << inference_time
              << ",\"output\":" << output << "}" << std::endl;
#endif

    // Print metrics every 5 inferences
    if (inference_count % 5 == 0)
    {
      std::cout << "METRICS: {"
                << "\"inference_count\":" << inference_count
                << ",\"avg_inference_time_ms\":" << (total_inference_time / inference_count)
                << ",\"max_inference_time_ms\":" << max_inference_time
#ifdef WINDOWS
                << ",\"free_memory_bytes\":" << ESP::getFreeHeap()
#else
                << ",\"free_memory_bytes\":0"
#endif
                << "}" << std::endl;
    }
  }
}

int main()
{
  setup();
  while (true)
  {
    loop();
  }
  return 0;
}