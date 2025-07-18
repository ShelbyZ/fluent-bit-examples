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
./examples.sh [--aws] [--image IMAGE] [--yaml|--conf] EXAMPLE_NAME
```

Where:
- `EXAMPLE_NAME` is either `basic` or `systemd`
- `--aws` (optional) flag indicates to use the AWS Fluent Bit image and configuration
- `--image IMAGE` (optional) specifies a custom Fluent Bit Docker image to use
- `--yaml` (optional) forces the use of YAML configuration file with a custom image
- `--conf` (optional) forces the use of CONF configuration file with a custom image

Note: The `--yaml` and `--conf` flags can only be used with the `--image` flag, and the `--aws` flag cannot be used with `--image`.

The script will:
1. Check if the specified example directory exists
2. Clean up any previous output for that example
3. Create a new output directory with an appropriate suffix:
   - Standard mode: `output/EXAMPLE_NAME`
   - AWS mode: `output/EXAMPLE_NAME-aws`
   - Custom image mode: `output/EXAMPLE_NAME-custom`
4. Run Fluent Bit in a Docker container with the example configuration
5. Store the output in the created directory

### Image and Configuration Options

#### AWS Mode

When the `--aws` flag is used:
- The script will use the `amazon/aws-for-fluent-bit:latest` Docker image
- Configuration will use the `.conf` format instead of `.yaml`
- Output will be stored in a directory with the `-aws` suffix

#### Custom Image Mode

When the `--image` flag is used:
- The script will use the specified Docker image
- By default, configuration will use the `.conf` format (safer option)
- You can override the configuration format with `--yaml` or `--conf` flags
- The `--aws` flag cannot be used with `--image`
- Output will be stored in a directory with the `-custom` suffix

#### Configuration Format Selection

- Standard mode: Uses `.yaml` configuration by default
- AWS mode: Uses `.conf` configuration by default
- Custom image mode: Uses `.conf` configuration by default, but can be overridden with `--yaml` or `--conf` flags

## Available Examples

You can run each example in standard mode, AWS mode, or with a custom image:

```bash
# Standard mode examples
./examples.sh basic
./examples.sh systemd

# AWS mode examples
./examples.sh --aws basic
./examples.sh --aws systemd

# Custom image examples
./examples.sh --image fluent/fluent-bit:2.1.0 basic
./examples.sh --image fluent/fluent-bit:2.1.0 --yaml systemd
./examples.sh --image custom/fluent-bit:latest --conf basic
```

### basic

The basic example demonstrates a simple Fluent Bit configuration that:

- Uses the `dummy` input plugin to generate test data (JSON messages)
- Outputs the data to both stdout and a file
- Includes a JSON parser configuration
- Sets up logging to track Fluent Bit's operation

#### Configuration Details

The basic example configuration is available in two formats:
- YAML format: `basic/fluent-bit.yaml` (used by default in standard mode)
- Config format: `basic/fluent-bit.conf` (used with `--aws` flag or custom images by default)

#### Output

When you run the basic example, it will:

1. Generate dummy JSON messages at a rate of 1 per second
2. Output these messages to stdout in JSON lines format
3. Write the same messages to a file:
   - Standard mode: `output/basic/file.log`
   - AWS mode: `output/basic-aws/file.log`
   - Custom image mode: `output/basic-custom/file.log`
4. Create a detailed log of Fluent Bit's operation:
   - Standard mode: `output/basic/fluent-bit.log`
   - AWS mode: `output/basic-aws/fluent-bit.log`
   - Custom image mode: `output/basic-custom/fluent-bit.log`

### systemd

The systemd example demonstrates how to collect and process logs from systemd journal:

- Uses the `systemd` input plugin to collect logs from systemd journal
- Specifically filters for logs from the `simple-logger.service`
- Outputs the collected logs to both stdout and a file
- Includes a JSON parser configuration
- Sets up logging to track Fluent Bit's operation

#### Configuration Details

The systemd example configuration is available in two formats:
- YAML format: `systemd/fluent-bit.yaml` (used by default in standard mode)
- Config format: `systemd/fluent-bit.conf` (used with `--aws` flag or custom images by default)

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
   - Using one of the following images based on the provided flags:
     - Standard Fluent Bit image (`fluent/fluent-bit:latest-debug`) by default
     - AWS Fluent Bit image (`amazon/aws-for-fluent-bit:latest`) when using `--aws`
     - Custom image specified with `--image` flag
6. When Fluent Bit exits or if the script is interrupted (Ctrl+C), the script will:
   - Stop the simple-logger process
   - Deactivate the Python virtual environment
   - Clean up all resources

#### Output

The systemd example will:

1. Collect logs from the systemd journal for the simple-logger service
2. Output these logs to stdout in JSON lines format
3. Write the same logs to a file:
   - Standard mode: `output/systemd/file.log`
   - AWS mode: `output/systemd-aws/file.log`
   - Custom image mode: `output/systemd-custom/file.log`
4. Create a detailed log of Fluent Bit's operation:
   - Standard mode: `output/systemd/fluent-bit.log`
   - AWS mode: `output/systemd-aws/fluent-bit.log`
   - Custom image mode: `output/systemd-custom/fluent-bit.log`

## Error Handling

The script includes robust error handling to ensure a smooth experience:

- Checks for required tools (Docker, Python, etc.) before running examples
- Verifies that directories and files exist before using them
- Properly cleans up resources (background processes, virtual environments) even when interrupted
- Provides clear error messages if something goes wrong

If you encounter any issues, check the error messages for guidance on how to resolve them.

## License

See the [LICENSE](LICENSE) file for details.
