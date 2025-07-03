# Justkill

Justkill is a cross-platform command-line utility that kills processes running on a specified port. It's useful for developers who need to quickly free up ports that are being used by other applications.

## Features

- Cross-platform support for Windows and Unix-like systems (Linux, macOS)
- Simple command-line interface
- Native executable support via GraalVM for better performance

## Requirements

- Java 17 or higher (for running from source or JAR)
- GraalVM with native-image tool (for building native executable)
- On Unix-like systems: `lsof` command
- On Windows: `netstat` and `taskkill` commands (included in standard Windows installations)

## Installation

### Option 1: Build from source using Maven

```bash
# Clone the repository
git clone https://github.com/yourusername/Jkill.git
cd Jkill

# Build with Maven
mvn clean package

# Run the JAR
java -jar target/jkill-1.0.jar <port>

# Optionally, build native executable
mvn -Pnative package
```

### Option 2: Build native executable directly

#### Unix-like systems (Linux, macOS)

```bash
# Clone the repository
git clone https://github.com/yourusername/Jkill.git
cd Jkill

# Run the build script
./build-direkt.sh

# Install the executable
sudo cp target/jkill /usr/local/bin/
sudo chmod +x /usr/local/bin/jkill
```

#### Windows

```batch
# Clone the repository
git clone https://github.com/yourusername/Jkill.git
cd Jkill

# Run the build script
build-direkt.bat

# The executable will be created at target\jkill.exe
# You can add it to your PATH or copy it to a directory in your PATH
```

## Usage

```
jkill <port> [options]
```

### Options

- `-h, --help`: Show help message and exit
- `-V, --version`: Print version information and exit

### Examples

Kill all processes running on port 8080:
```
jkill 8080
```

Show help:
```
jkill --help
```

## How It Works

Jkill uses different approaches depending on the operating system:

### On Unix-like systems (Linux, macOS)

1. Uses `lsof -ti :<port>` to find process IDs using the specified port
2. Uses `kill -9 <pid>` to terminate each process

### On Windows

1. Uses `netstat -ano` to find process IDs using the specified port
2. Uses `taskkill /F /PID <pid>` to terminate each process

## License

This project is licensed under the [MIT License](LICENSE).

You are free to use, modify, and distribute this tool.
If you use it in your own projects or redistribute it, attribution is appreciated (e.g., a mention in your README or documentation), but not required.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
