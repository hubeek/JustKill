#!/bin/bash

echo "Building jkill using direct native-image (bypassing Maven plugin)..."

# Check if source is in Maven structure
if [ ! -f "src/main/java/nl/appall/jkill/Jkill.java" ]; then
    echo "Moving to Maven structure..."
    mkdir -p src/main/java
    if [ -f "nl/appall/jkill/Jkill.java" ]; then
        mv nl src/main/java/
        echo "Moved nl/ to src/main/java/"
    else
        echo "Error: Cannot find Jkill.java in expected locations"
        exit 1
    fi
fi

# Use Maven to compile and get dependencies
echo "Using Maven to compile Java and resolve dependencies..."
mvn clean compile dependency:copy-dependencies

# Check if compilation was successful
if [ ! -f "target/classes/nl/appall/jkill/Jkill.class" ]; then
    echo "Error: Maven compilation failed."
    exit 1
fi

echo "Compilation successful. Checking dependencies..."

# Find the picocli dependency
PICOCLI_JAR=$(find target/dependency -name "picocli-*.jar" | head -1)

if [ -z "$PICOCLI_JAR" ]; then
    echo "Error: picocli JAR not found in dependencies."
    echo "Available JARs:"
    ls -la target/dependency/
    exit 1
fi

echo "Using picocli JAR: $PICOCLI_JAR"

# Check if native-image is available
if ! command -v native-image &> /dev/null; then
    echo "Error: native-image command not found."
    echo "Your JAVA_HOME: $JAVA_HOME"
    echo "Please install native-image: gu install native-image"
    exit 1
fi

echo "native-image version:"
native-image --version

# Test the JAR first
echo "Testing JAR before building native image..."
java -cp "target/classes:$PICOCLI_JAR" nl.appall.jkill.Jkill --help

if [ $? -ne 0 ]; then
    echo "Error: JAR test failed. Cannot proceed with native-image."
    exit 1
fi

echo "JAR test successful. Building native executable..."

# Build native image with verbose output
native-image \
    -cp "target/classes:$PICOCLI_JAR" \
    --no-fallback \
    -H:Name=jkill \
    -H:Class=nl.appall.jkill.Jkill \
    -H:Path=target \
    --verbose

# Check if build was successful
if [ $? -ne 0 ]; then
    echo "Native image build failed. Trying without --no-fallback..."
    native-image \
        -cp "target/classes:$PICOCLI_JAR" \
        -H:Name=jkill \
        -H:Class=nl.appall.jkill.Jkill \
        -H:Path=target \
        --verbose
fi

# Test the executable
if [ -f "target/jkill" ]; then
    echo "Build successful! Testing executable..."
    ./target/jkill --help
    echo ""
    echo "Success! Install with:"
    echo "  sudo cp target/jkill /usr/local/bin/"
    echo "  sudo chmod +x /usr/local/bin/jkill"
else
    echo "Error: Executable not created."
    exit 1
fi
