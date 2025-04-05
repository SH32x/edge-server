import sys
import os
import numpy as np

# Check if the output path is provided
if len(sys.argv) < 2:
    print("Usage: python generate_model.py <output_path>")
    sys.exit(1)

output_path = sys.argv[1]
output_dir = os.path.dirname(output_path)

# Create output directory if it doesn't exist
if not os.path.exists(output_dir):
    os.makedirs(output_dir)

try:
    # Try to import TensorFlow and create a model
    import tensorflow as tf

    # Create a simple model
    model = tf.keras.Sequential(
        [
            tf.keras.layers.InputLayer(input_shape=(4,)),
            tf.keras.layers.Dense(8, activation="relu"),
            tf.keras.layers.Dense(1),
        ]
    )

    # Compile the model
    model.compile(optimizer="adam", loss="mse")

    # Train with dummy data
    x = np.random.random((10, 4))
    y = np.random.random((10, 1))
    model.fit(x, y, epochs=1, verbose=0)

    # Convert to TFLite
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    tflite_model = converter.convert()

    # Save the model
    with open(output_path, "wb") as f:
        f.write(tflite_model)

    print(f"Sample TFLite model created successfully at {output_path}")

except ImportError as e:
    print(f"Error importing TensorFlow: {e}")
    print("Creating a dummy model file instead...")

    # Create a simple dummy model (just a binary file with some content)
    dummy_content = bytearray([0x00, 0x01, 0x02, 0x03] * 256)  # 1KB dummy file
    with open(output_path, "wb") as f:
        f.write(dummy_content)

    print(f"Dummy model file created at {output_path}")

except Exception as e:
    print(f"Error creating model: {e}")
    sys.exit(1)
