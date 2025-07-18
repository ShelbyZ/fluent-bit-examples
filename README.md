# Fluent Bit Examples

This repository contains a collection of examples demonstrating various Fluent Bit configurations and use cases. Each example is organized in its own directory and can be run using the provided `examples.sh` script.

## Requirements

- Docker installed and running
- Bash shell
- For the systemd example:
  - Python 3 with venv module
  - Git (to clone the simple-logger repository)

## Usage

To run any example, use the `examples.sh` script followed by the example name:

```bash
./examples.sh EXAMPLE_NAME
```

The script will:
1. Check if the specified example directory exists
2. Clean up any previous output for that example
3. Create a new output directory
4. Run Fluent Bit in a Docker container with the example configuration
5. Store the output in the `output/EXAMPLE_NAME` directory

## Available Examples

### basic

The basic example demonstrates a simple Fluent Bit configuration that:

- Uses the `dummy` input plugin to generate test data (JSON messages)
- Outputs the data to both stdout and a file
- Includes a JSON parser configuration
- Sets up logging to track Fluent Bit's operation

#### Configuration Details

The basic example configuration is located at `basic/fluent-bit.yaml`.

#### Output

When you run the basic example, it will:

1. Generate dummy JSON messages at a rate of 1 per second
2. Output these messages to stdout in JSON lines format
3. Write the same messages to a file `output/basic/file.log`
4. Create a detailed log of Fluent Bit's operation `output/basic/fluent-bit.log`

### systemd

The systemd example demonstrates how to collect and process logs from systemd journal:

- Uses the `systemd` input plugin to collect logs from systemd journal
- Specifically filters for logs from the `simple-logger.service`
- Outputs the collected logs to both stdout and a file
- Includes a JSON parser configuration
- Sets up logging to track Fluent Bit's operation

#### Configuration Details

The systemd example configuration is located at `systemd/fluent-bit.yaml`.

#### Special Handling

When you run the systemd example with `./examples.sh systemd`, the script will:

1. Clone the [simple-logger](https://github.com/ShelbyZ/simple-logger) tool into the `./temp` directory (if not already cloned)
2. Set up a Python virtual environment (if not already created) and install required dependencies
3. Activate the virtual environment and run simple-logger in the background with specific environment variables:
   - `ENABLE_JOURNALD=true` to send logs to the systemd journal
   - `LOGS_PER_MINUTE=10` to control the rate of log generation
4. Verify that the simple-logger process started successfully
5. Start Fluent Bit in a Docker container with:
   - Privileged mode to access system resources
   - The host's journal directory mounted as read-only `/var/log/journal`
6. When Fluent Bit exits or if the script is interrupted (Ctrl+C), the script will:
   - Stop the simple-logger process
   - Deactivate the Python virtual environment
   - Clean up all resources

#### Output

The systemd example will:

1. Collect logs from the systemd journal for the simple-logger service
2. Output these logs to stdout in JSON lines format
3. Write the same logs to a file `output/systemd/file.log`
4. Create a detailed log of Fluent Bit's operation `output/systemd/fluent-bit.log`

## Error Handling

The script includes robust error handling to ensure a smooth experience:

- Checks for required tools (Docker, Python, etc.) before running examples
- Verifies that directories and files exist before using them
- Properly cleans up resources (background processes, virtual environments) even when interrupted
- Provides clear error messages if something goes wrong

If you encounter any issues, check the error messages for guidance on how to resolve them.

## License

See the [LICENSE](LICENSE) file for details.