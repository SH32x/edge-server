#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <chrono>
#include <thread>
#include <random>
#include <cmath>
#include <algorithm>
#include <sstream>

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

// Simple self-learning neural network
class SimpleNeuralNetwork
{
private:
  // Network architecture
  size_t inputSize;
  size_t hiddenSize;
  size_t outputSize;
  
  // Weights and biases
  std::vector<std::vector<float>> weightsInputHidden;
  std::vector<float> biasesHidden;
  std::vector<std::vector<float>> weightsHiddenOutput;
  std::vector<float> biasesOutput;
  
  // Target function weights (what we're trying to learn)
  std::vector<float> targetWeights;
  
  // Learning parameters
  float learningRate;
  
  // Cached values for training
  std::vector<float> lastInput;
  std::vector<float> hiddenOutputs;
  
  // Simple activation function
  float relu(float x) const {
    return std::max(0.0f, x);
  }
  
  // Initialize with small random weights
  void initialize(unsigned int seed = 42) {
    std::mt19937 rng(seed);
    std::uniform_real_distribution<float> dist(-0.1f, 0.1f);
    
    // Input to hidden weights
    weightsInputHidden.resize(hiddenSize);
    for (size_t i = 0; i < hiddenSize; ++i) {
      weightsInputHidden[i].resize(inputSize);
      for (size_t j = 0; j < inputSize; ++j) {
        weightsInputHidden[i][j] = dist(rng);
      }
    }
    
    // Hidden biases
    biasesHidden.resize(hiddenSize);
    for (size_t i = 0; i < hiddenSize; ++i) {
      biasesHidden[i] = dist(rng);
    }
    
    // Hidden to output weights
    weightsHiddenOutput.resize(outputSize);
    for (size_t i = 0; i < outputSize; ++i) {
      weightsHiddenOutput[i].resize(hiddenSize);
      for (size_t j = 0; j < hiddenSize; ++j) {
        weightsHiddenOutput[i][j] = dist(rng);
      }
    }
    
    // Output biases
    biasesOutput.resize(outputSize);
    for (size_t i = 0; i < outputSize; ++i) {
      biasesOutput[i] = dist(rng);
    }
  }
  
  // Calculate the target value based on the weighted sum formula
  float calculateTarget(const std::vector<float>& input) const {
    float target = 0.0f;
    for (size_t i = 0; i < std::min(input.size(), targetWeights.size()); ++i) {
      target += input[i] * targetWeights[i];
    }
    return target;
  }
  
  // Apply a small update to weights after each prediction
  void updateWeights(float prediction) {
    // Only update if we have cached input
    if (lastInput.empty()) return;
    
    // Calculate target using weighted sum formula
    float target = calculateTarget(lastInput);
    
    // Error: difference between prediction and target
    float error = target - prediction;
    
    // Small weight adjustments to reduce the error
    // This is a simplified version of backpropagation
    
    // Update output weights and bias
    for (size_t i = 0; i < hiddenSize; ++i) {
      weightsHiddenOutput[0][i] += learningRate * error * hiddenOutputs[i];
    }
    biasesOutput[0] += learningRate * error;
    
    // Update hidden layer weights and biases (simplified)
    for (size_t i = 0; i < hiddenSize; ++i) {
      for (size_t j = 0; j < inputSize; ++j) {
        weightsInputHidden[i][j] += learningRate * error * 0.1f * lastInput[j];
      }
      biasesHidden[i] += learningRate * error * 0.05f;
    }
  }

public:
  SimpleNeuralNetwork(size_t inputSize = 4, size_t hiddenSize = 4, size_t outputSize = 1) 
    : inputSize(inputSize), hiddenSize(hiddenSize), outputSize(outputSize),
      learningRate(0.035f) {
    
    // Initialize the network
    initialize();
    hiddenOutputs.resize(hiddenSize);
    
    // Set target weights for the weighted sum formula
    targetWeights = {0.1f, 0.2f, 0.3f, 0.4f};
  }
  
  float predict(const float* input, size_t size) {
    // Cache the input for training
    lastInput.clear();
    lastInput.insert(lastInput.end(), input, input + size);
    
    // Ensure input is properly sized
    if (lastInput.size() < inputSize) {
      lastInput.resize(inputSize, 0.0f);
    }
    
    // Calculate hidden layer outputs
    for (size_t i = 0; i < hiddenSize; ++i) {
      float sum = biasesHidden[i];
      for (size_t j = 0; j < inputSize; ++j) {
        sum += weightsInputHidden[i][j] * lastInput[j];
      }
      hiddenOutputs[i] = relu(sum);
    }
    
    // Calculate output
    float output = biasesOutput[0];
    for (size_t i = 0; i < hiddenSize; ++i) {
      output += weightsHiddenOutput[0][i] * hiddenOutputs[i] + 0.03;
    }
    
    // Update weights to gradually approach target
    updateWeights(output);
    
    return output;
  }
  
  // For debugging/comparison: calculate the exact target value
  float getExactTarget(const float* input, size_t size) {
    std::vector<float> inputVec(input, input + size);
    return calculateTarget(inputVec);
  }
  
  // Modify learning rate
  void setLearningRate(float rate) {
    learningRate = rate;
  }
};

// Global variables
SimpleNeuralNetwork* model = nullptr;
unsigned long inference_count = 0;

// Helper function to parse simplified input format [1.0, 2.0, 3.0, 4.0]
bool parseInput(const std::string& input, std::vector<float>& values) {
    values.clear();
    
    // Check for array format with square brackets
    if (input.empty() || input.front() != '[' || input.back() != ']') {
        return false;
    }
    
    // Extract content between brackets
    std::string content = input.substr(1, input.length() - 2);
    
    // Parse comma-separated values
    std::stringstream ss(content);
    std::string item;
    
    while (getline(ss, item, ',')) {
        // Trim spaces
        item.erase(0, item.find_first_not_of(" "));
        item.erase(item.find_last_not_of(" ") + 1);
        
        try {
            float value = std::stof(item);
            values.push_back(value);
        } catch (const std::exception& e) {
            return false;
        }
    }
    
    return !values.empty();
}

void setup()
{
  std::cout << "Neural Network Inference Simulator Starting..." << std::endl;

  // Initialize model - simple self-learning neural network
  model = new SimpleNeuralNetwork(4, 4, 1);

  std::cout << "Neural Network Simulator Ready!" << std::endl;
  std::cout << "Enter input values in the format: [1.0, 2.0, 3.0, 4.0]" << std::endl;
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

    // Parse simplified input format
    std::vector<float> input;
    if (!parseInput(line, input)) {
      std::cout << "Invalid input format. Expected: [values]" << std::endl;
      return;
    }

    // Calculate the exact target for comparison
    float exactTarget = model->getExactTarget(input.data(), input.size());
    std::cout << "Target value: " << exactTarget << std::endl;
    
    // Reset inference counter
    inference_count = 0;
    
    // Automatic learning loop until convergence
    std::cout << "Learning to approximate target..." << std::endl;
    
    // Initial prediction
    float output = model->predict(input.data(), input.size());
    float initialOutput = output;
    inference_count++;
    
    // Output the initial prediction in the requested format
    std::cout << "{\"status\":\"success\",\"output\":" << output << "}" << std::endl;
    
    // Continue until we get close to target or max iterations reached
    const float TOLERANCE = 0.01f; // How close to target is considered success
    const int MAX_ITERATIONS = 300; // Safety limit on iterations
    
    while (std::abs(output - exactTarget) > TOLERANCE && inference_count < MAX_ITERATIONS) {
      // Make another prediction (which also updates weights)
      output = model->predict(input.data(), input.size());
      inference_count++;
      
      // Output result
      std::cout << "{\"status\":\"success\",\"output\":" << output << "}" << std::endl;
      
      // Optional slight delay for better visualization
      std::this_thread::sleep_for(std::chrono::milliseconds(50));
    }
    
    // Summary
    std::cout << "\nLearning complete!" << std::endl;
    std::cout << "Initial output: " << initialOutput << std::endl;
    std::cout << "Final output: " << output << std::endl;
    std::cout << "Target: " << exactTarget << std::endl;
    std::cout << "Error: " << std::abs(output - exactTarget) << std::endl;
    std::cout << "Iterations: " << inference_count << std::endl;
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