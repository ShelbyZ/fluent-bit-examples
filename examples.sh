#!/bin/bash

# Global variable to store logger PID
LOGGER_PID=""
VENV_ACTIVATED=0
USE_AWS=0

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
    echo "Usage: $0 [--aws] [--image IMAGE] [--yaml|--conf] EXAMPLE_NAME"
    echo "  EXAMPLE_NAME    Name of the example to run (basic or systemd)"
    echo "  --aws           Use AWS Fluent Bit image and configuration (cannot be used with --image)"
    echo "  --image IMAGE   Use custom Fluent Bit image (cannot be used with --aws)"
    echo "  --yaml          Use YAML configuration file with custom image (default for standard image)"
    echo "  --conf          Use CONF configuration file with custom image (default for custom and AWS images)"
    exit 1
}

# Parse command line arguments
EXAMPLE=""
CUSTOM_IMAGE=""
USE_YAML=0
USE_CONF=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --aws)
            USE_AWS=1
            shift
            ;;
        --image)
            if [[ -z "$2" || "$2" == --* ]]; then
                echo "Error: --image requires an argument"
                usage
            fi
            CUSTOM_IMAGE="$2"
            shift 2
            ;;
        --yaml)
            USE_YAML=1
            shift
            ;;
        --conf)
            USE_CONF=1
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            if [ -z "$EXAMPLE" ]; then
                EXAMPLE="$1"
            else
                echo "Error: Unexpected argument: $1"
                usage
            fi
            shift
            ;;
    esac
done

# Check if example name is provided
if [ -z "$EXAMPLE" ]; then
    echo "Error: No example name provided!"
    usage
fi

# Validate configuration options
if [[ $USE_YAML -eq 1 && $USE_CONF -eq 1 ]]; then
    echo "Error: Cannot use both --yaml and --conf at the same time"
    usage
fi

# Validate that --yaml and --conf are only used with --image
if [[ -z "$CUSTOM_IMAGE" && ($USE_YAML -eq 1 || $USE_CONF -eq 1) ]]; then
    echo "Error: --yaml and --conf flags can only be used with --image"
    usage
fi

# Validate that --aws is not used with --image
if [[ ! -z "$CUSTOM_IMAGE" && $USE_AWS -eq 1 ]]; then
    echo "Error: --aws flag cannot be used with --image"
    usage
fi

# Set output directory based on example and flags
OUTPUT_DIR="$EXAMPLE"
if [ $USE_AWS -eq 1 ]; then
    OUTPUT_DIR="${EXAMPLE}-aws"
elif [ ! -z "$CUSTOM_IMAGE" ]; then
    OUTPUT_DIR="${EXAMPLE}-custom"
fi

# Check if example directory exists
if [ ! -d "./$EXAMPLE" ]; then
    echo "Error: Example directory './$EXAMPLE' not found!"
    exit 1
fi

# Clean up and recreate output directory
if [ -d "./output/$OUTPUT_DIR" ]; then
    echo "Cleaning output directory for example: $OUTPUT_DIR"
    rm -rf "./output/$OUTPUT_DIR"
fi
mkdir -p "./output/$OUTPUT_DIR"

echo "Running example: $EXAMPLE"
if [ ! -z "$CUSTOM_IMAGE" ]; then
    echo "Using custom Fluent Bit image: $CUSTOM_IMAGE"
elif [ $USE_AWS -eq 1 ]; then
    echo "Using AWS Fluent Bit image and configuration"
else
    echo "Using standard Fluent Bit image"
fi
echo "Configuration from: ./$EXAMPLE"
echo "Output to: ./output/$OUTPUT_DIR"

# Special handling for systemd example
if [ "$EXAMPLE" == "systemd" ]; then
    echo "Setting up systemd example with simple-logger..."
    # Setup and run simple-logger in the background
    echo "Cloning simple-logger..."
    if [ -d "./temp/simple-logger" ]; then
        rm -rf ./temp
    fi
    git clone --single-branch --branch main https://github.com/ShelbyZ/simple-logger.git ./temp/simple-logger
    cd ./temp/simple-logger

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
# Define variables based on configuration
if [ ! -z "$CUSTOM_IMAGE" ]; then
    # Custom image specified
    FB_IMAGE="$CUSTOM_IMAGE"
    
    # Determine config file based on flags or defaults
    if [ $USE_CONF -eq 1 ]; then
        FB_CONFIG="fluent-bit.conf"
    elif [ $USE_YAML -eq 1 ]; then
        FB_CONFIG="fluent-bit.yaml"
    else
        # Default to conf for custom images (safer)
        FB_CONFIG="fluent-bit.conf"
    fi
elif [ $USE_AWS -eq 1 ]; then
    # AWS image
    FB_IMAGE="amazon/aws-for-fluent-bit:latest"
    FB_CONFIG="fluent-bit.conf"
else
    # Standard image
    FB_IMAGE="fluent/fluent-bit:latest-debug"
    FB_CONFIG="fluent-bit.yaml"
fi

# Run Docker with the defined variables
docker run --rm \
    --privileged \
    -v "$(pwd)/$EXAMPLE:/fluent-bit/etc" \
    -v "$(pwd)/output/$OUTPUT_DIR:/output" \
    -v /var/log/journal:/var/log/journal:ro \
    $FB_IMAGE \
    /fluent-bit/bin/fluent-bit -c /fluent-bit/etc/$FB_CONFIG
