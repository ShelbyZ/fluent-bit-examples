# journald-config.sh

A utility script for managing systemd-journald settings related to keyed hash and compression.

Related to: https://github.com/fluent/fluent-bit/issues/2998

## Overview

This script provides a command-line interface to manage two important systemd-journald settings:

1. **SYSTEMD_JOURNAL_KEYED_HASH** environment variable - Controls whether systemd-journald uses keyed hashing for log entries
2. **Compress** option in journald.conf - Controls whether journal files are compressed

## Requirements

- Linux system with systemd
- sudo/root privileges
- Bash shell

## Usage

```
./journald-config.sh [OPTION]
```

### Options for SYSTEMD_JOURNAL_KEYED_HASH

| Option | Description |
|--------|-------------|
| `enable-hash` | Enable SYSTEMD_JOURNAL_KEYED_HASH (set to 1) |
| `disable-hash` | Disable SYSTEMD_JOURNAL_KEYED_HASH (set to 0) |
| `reset-hash` | Remove custom hash configuration (use system defaults) |

### Options for Journal Compression

| Option | Description |
|--------|-------------|
| `enable-compress` | Enable journal compression |
| `disable-compress` | Disable journal compression |
| `reset-compress` | Reset compression to system default |

### General Options

| Option | Description |
|--------|-------------|
| `status` | Check current status of all settings |
| `help` | Display help message |

## Examples

Check the current status of all settings:
```bash
sudo ./journald-config.sh status
```

Enable keyed hash for systemd-journald:
```bash
sudo ./journald-config.sh enable-hash
```

Disable journal compression:
```bash
sudo ./journald-config.sh disable-compress
```

Reset all settings to system defaults:
```bash
sudo ./journald-config.sh reset-hash
sudo ./journald-config.sh reset-compress
```

## Configuration Files

The script manages the following configuration files:

- `/etc/systemd/system/systemd-journald.service.d/journal-keyed-hash.conf` - For SYSTEMD_JOURNAL_KEYED_HASH setting
- `/etc/systemd/journald.conf` - For Compress setting

## Technical Details

### SYSTEMD_JOURNAL_KEYED_HASH

This environment variable controls whether systemd-journald uses keyed hashing for log entries:

- When enabled (set to 1), systemd-journald uses a keyed hash function to compute identifiers for log entries
- When disabled (set to 0), systemd-journald uses a plain hash function
- The default depends on your systemd version (typically enabled by default in systemd ≥ 246)

Enabling keyed hash can improve security by making it harder to perform denial-of-service attacks against the journal.

### Journal Compression

The Compress option in journald.conf controls whether journal files are compressed:

- When enabled (set to "yes"), journal files are compressed to save disk space
- When disabled (set to "no"), journal files are not compressed
- The default is typically "yes" (compression enabled)

Disabling compression may improve performance at the cost of increased disk usage.

## Troubleshooting

If you encounter permission errors, make sure you're running the script with sudo privileges:

```bash
sudo ./journald-config.sh [OPTION]
```

To verify that your changes have been applied, use the status option:

```bash
sudo ./journald-config.sh status
```
