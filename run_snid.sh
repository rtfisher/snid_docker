#!/bin/bash

# Function to clean up X11 permissions
cleanup() {
    echo "Revoking X11 permissions for 127.0.0.1..."
    xhost - 127.0.0.1
    exit
}

# Trap EXIT and INT signals to ensure cleanup is called
trap cleanup EXIT INT

# Launch Docker Desktop
echo "Launching Docker Desktop..."
open -a Docker

# Wait for Docker to be ready
echo "Waiting for Docker to start..."
while ! docker system info > /dev/null 2>&1; do
    sleep 1
done
echo "Docker is up and running."

# Launch XQuartz
echo "Launching XQuartz..."
open -a XQuartz

# Wait briefly to ensure XQuartz is fully started
sleep 2

# Build Docker container for SNID
docker build -t snid-app --progress=plain -f snid_dockerfile .

# Allow connections from Docker containers
echo "Configuring XQuartz to allow connections from Docker..."
xhost + 127.0.0.1

# Run the Docker container with X11 forwarding
echo "Running Docker container 'snid-app'..."
docker run -it --rm \
    -e DISPLAY=host.docker.internal:0 \
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    -v ~/Desktop/snid:/home/sniduser/snid-5.0/desktop \
    snid-app

