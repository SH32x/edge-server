#include <Arduino.h>
#include <TensorFlowLite.h>
#include "tensorflow/lite/micro/all_ops_resolver.h"
#include "tensorflow/lite/micro/micro_error_reporter.h"
#include "tensorflow/lite/micro/micro_interpreter.h"
#include "tensorflow/lite/schema/schema_generated.h"
#include "tensorflow/lite/version.h"
#include <ArduinoJson.h>

// If we have a specific model header, include it
// #include "model.h"
// Otherwise we'll use an embedded file and access it by symbol

extern const unsigned char model_tflite[] asm("_binary_src_model_tflite_start");
extern const unsigned char model_tflite_end[] asm("_binary_src_model_tflite_end");

// Globals for TensorFlow Lite
namespace {
  tflite::ErrorReporter* error_reporter = nullptr;
  const tflite::Model* model = nullptr;
  tflite::MicroInterpreter* interpreter = nullptr;
  TfLiteTensor* input = nullptr;
  TfLiteTensor* output = nullptr;
  
  // Create an area of memory to use for input, output, and intermediate arrays
  // Adjust this based on your particular model
  constexpr int kTensorArenaSize = 50 * 1024;
  uint8_t tensor_arena[kTensorArenaSize];
}

// Metrics tracking
unsigned long inference_count = 0;
unsigned long total_inference_time = 0;
unsigned long max_inference_time = 0;
unsigned long memory_usage = 0;
unsigned long last_metrics_time = 0;

void setup() {
  Serial.begin(115200);
  
  // Wait for serial to connect
  delay(1000);
  
  Serial.println("TensorFlow Lite Microcontroller Inference Starting...");
  
  // Set up logging
  static tflite::MicroErrorReporter micro_error_reporter;
  error_reporter = &micro_error_reporter;
  
  // Map the model into a usable data structure
  model = tflite::GetModel(model_tflite);
  if (model->version() != TFLITE_SCHEMA_VERSION) {
    TF_LITE_REPORT_ERROR(error_reporter,
                         "Model provided is schema version %d not equal "
                         "to supported version %d.",
                         model->version(), TFLITE_SCHEMA_VERSION);
    return;
  }
  
  // Pull in all needed operations
  static tflite::AllOpsResolver resolver;
  
  // Build an interpreter to run the model
  static tflite::MicroInterpreter static_interpreter(
      model, resolver, tensor_arena, kTensorArenaSize, error_reporter);
  interpreter = &static_interpreter;
  
  // Allocate memory from the tensor_arena for the model's tensors
  TfLiteStatus allocate_status = interpreter->AllocateTensors();
  if (allocate_status != kTfLiteOk) {
    TF_LITE_REPORT_ERROR(error_reporter, "AllocateTensors() failed");
    return;
  }
  
  // Get pointers to the model's input and output tensors
  input = interpreter->input(0);
  output = interpreter->output(0);
  
  // Log tensor information
  Serial.print("Input tensor dimensions: ");
  for (int i = 0; i < input->dims->size; i++) {
    Serial.print(input->dims->data[i]);
    if (i < input->dims->size - 1) Serial.print("x");
  }
  Serial.println();
  
  Serial.print("Output tensor dimensions: ");
  for (int i = 0; i < output->dims->size; i++) {
    Serial.print(output->dims->data[i]);
    if (i < output->dims->size - 1) Serial.print("x");
  }
  Serial.println();
  
  Serial.println("TensorFlow Lite Microcontroller Inference Ready!");
  
  // Initialize memory tracking
  memory_usage = ESP.getFreeHeap();
}

void loop() {
  // Create sample input data (modify according to your model's expected input)
  float sample_input[4] = {1.0, 2.0, 3.0, 4.0};
  
  // Check if we have input from Serial
  if (Serial.available()) {
    String json_input = Serial.readStringUntil('\n');
    
    // Parse JSON
    DynamicJsonDocument doc(1024);
    DeserializationError error = deserializeJson(doc, json_input);
    
    if (!error) {
      // If JSON has an "input" array, use it
      if (doc.containsKey("input") && doc["input"].is<JsonArray>()) {
        JsonArray input_array = doc["input"];
        int i = 0;
        for (float value : input_array) {
          if (i < input->dims->data[input->dims->size - 1]) {
            sample_input[i++] = value;
          }
        }
      }
    }
  }
  
  // Copy the sample data to the input tensor
  for (int i = 0; i < 4; i++) {
    input->data.f[i] = sample_input[i];
  }
  
  // Run inference and measure time
  unsigned long start_time = millis();
  TfLiteStatus invoke_status = interpreter->Invoke();
  unsigned long inference_time = millis() - start_time;
  
  // Update metrics
  inference_count++;
  total_inference_time += inference_time;
  max_inference_time = max(max_inference_time, inference_time);
  
  if (invoke_status != kTfLiteOk) {
    TF_LITE_REPORT_ERROR(error_reporter, "Invoke failed");
    return;
  }
  
  // Output the results
  DynamicJsonDocument result_doc(1024);
  result_doc["status"] = "success";
  result_doc["inference_time_ms"] = inference_time;
  
  JsonArray result_array = result_doc.createNestedArray("output");
  for (int i = 0; i < output->dims->data[output->dims->size - 1]; i++) {
    result_array.add(output->data.f[i]);
  }
  
  serializeJson(result_doc, Serial);
  Serial.println();
  
  // Report metrics every 10 seconds
  if (millis() - last_metrics_time > 10000) {
    DynamicJsonDocument metrics_doc(1024);
    metrics_doc["metric_type"] = "status";
    metrics_doc["inference_count"] = inference_count;
    metrics_doc["avg_inference_time_ms"] = inference_count > 0 ? total_inference_time / inference_count : 0;
    metrics_doc["max_inference_time_ms"] = max_inference_time;
    metrics_doc["free_memory_bytes"] = ESP.getFreeHeap();
    metrics_doc["clock_speed_mhz"] = CLOCK_SPEED;
    
    Serial.print("METRICS: ");
    serializeJson(metrics_doc, Serial);
    Serial.println();
    
    last_metrics_time = millis();
  }
  
  // In simulation mode, add a delay to prevent flooding the serial output
  delay(1000);
}