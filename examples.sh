#!/bin/bash

# Global variable to store logger PID
LOGGER_PID=""
VENV_ACTIVATED=0

# Function to clean up resources
cleanup() {
    echo -e "\nCleaning up resources..."
    
    # Kill the logger process if it exists
    if [ ! -z "$LOGGER_PID" ] && ps -p $LOGGER_PID > /dev/null; then
        echo "Stopping simple-logger (PID: $LOGGER_PID)..."
        kill $LOGGER_PID
    fi
    
    # Deactivate virtual environment if it was activated
    if [ $VENV_ACTIVATED -eq 1 ] && [ -n "$VIRTUAL_ENV" ]; then
        echo "Deactivating Python virtual environment..."
        deactivate 2>/dev/null || true
    fi
    
    echo "Cleanup complete."
    exit 0
}

# Trap signals to ensure proper cleanup
trap cleanup SIGINT SIGTERM EXIT

# Function to display usage
usage() {
    echo "Usage: $0 EXAMPLE_NAME"
    echo "  EXAMPLE_NAME    Name of the example to run"
    exit 1
}

# Check if example name is provided
if [ $# -eq 0 ]; then
    echo "Error: No example name provided!"
    usage
fi

# Get example name from first argument
EXAMPLE="$1"

# Check if example directory exists
if [ ! -d "./$EXAMPLE" ]; then
    echo "Error: Example directory './$EXAMPLE' not found!"
    exit 1
fi

# Clean up and recreate output directory
if [ -d "./output/$EXAMPLE" ]; then
    echo "Cleaning output directory for example: $EXAMPLE"
    rm -rf "./output/$EXAMPLE"
fi
mkdir -p "./output/$EXAMPLE"

echo "Running example: $EXAMPLE"
echo "Configuration from: ./$EXAMPLE"
echo "Output to: ./output/$EXAMPLE"

# Special handling for systemd example
if [ "$EXAMPLE" == "systemd" ]; then
    echo "Setting up systemd example with simple-logger..."

    # Create temp directory if it doesn't exist
    mkdir -p ./temp

    # Setup and run simple-logger in the background
    echo "Cloning simple-logger..."
    cd ./temp

    if [ ! -d "simple-logger" ]; then
        git clone https://github.com/ShelbyZ/simple-logger.git
    fi

    cd simple-logger

    echo "Building simple-logger..."
    # Create a virtual environment
    if [ ! -d "venv" ]; then
        echo "Creating Python virtual environment..."
        python3 -m venv venv || {
            echo "Error: Failed to create Python virtual environment. Make sure python3-venv is installed."
            exit 1
        }
    fi
    
    echo "Activating virtual environment..."
    source venv/bin/activate || {
        echo "Error: Failed to activate virtual environment."
        exit 1
    }
    VENV_ACTIVATED=1
    
    echo "Installing dependencies..."
    pip install --quiet -r requirements.txt || {
        echo "Error: Failed to install dependencies."
        deactivate
        exit 1
    }

    echo "Running simple-logger in the background..."
    if [ ! -f "simple-logger.py" ]; then
        echo "Error: simple-logger.py not found!"
        deactivate
        exit 1
    fi
    
    ENABLE_JOURNALD=true LOGS_PER_MINUTE=10 python3 simple-logger.py &
    LOGGER_PID=$!
    
    # Verify the process started successfully
    if ! ps -p $LOGGER_PID > /dev/null; then
        echo "Error: Failed to start simple-logger."
        deactivate
        exit 1
    fi
    
    echo "Simple-logger started with PID: $LOGGER_PID"

    # Return to original directory
    cd ../..

    # Wait for logger to initialize
    echo "Waiting for simple-logger to initialize..."
    sleep 5
fi

echo "Starting Fluent Bit..."
# Check if Docker is available
if ! command -v docker &> /dev/null; then
    echo "Error: Docker is not installed or not in PATH."
    cleanup
    exit 1
fi

# Run Fluent Bit
docker run --rm \
    --privileged \
    -v "$(pwd)/$EXAMPLE:/fluent-bit/etc" \
    -v "$(pwd)/output/$EXAMPLE:/output" \
    -v /var/log/journal:/var/log/journal:ro \
    fluent/fluent-bit:latest-debug \
    /fluent-bit/bin/fluent-bit -c /fluent-bit/etc/fluent-bit.yaml
