#!/bin/bash

# Function to clean up X11 permissions
cleanup() {
    echo "Revoking X11 permissions for 127.0.0.1..."
    xhost - 127.0.0.1
    if [[ "$PLATFORM" == "Windows" ]]; then
        # Optionally, terminate the X11 server if desired
        if [[ -n "$XSERVER_PID" ]]; then
            echo "Terminating X11 server..."
            kill "$XSERVER_PID"
        fi
    fi
    exit
}

# Trap EXIT and INT signals to ensure cleanup is called
trap cleanup EXIT INT

# Detect the Operating System
OS_TYPE="$(uname)"

if [[ "$OS_TYPE" == "Darwin" ]]; then
    PLATFORM="macOS"
elif [[ "$OS_TYPE" == "Linux" ]]; then
    # Further check if it's WSL
    if grep -qi microsoft /proc/version; then
        PLATFORM="Windows"
    else
        PLATFORM="Linux"
    fi
else
    echo "Unsupported Operating System: $OS_TYPE"
    exit 1
fi

echo "Detected platform: $PLATFORM"

if [[ "$PLATFORM" == "macOS" ]]; then
    # Launch Docker Desktop
    echo "Launching Docker Desktop..."
    open -a Docker

    # Wait until Docker is ready
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

    # Allow connections from Docker containers
    echo "Configuring XQuartz to allow connections from Docker..."
    xhost + 127.0.0.1

elif [[ "$PLATFORM" == "Windows" ]]; then
    # Define default installation paths for VcXsrv, Xming, and Cygwin/X. Update if installed elsewhere.
    VCS_PATH="/mnt/c/Program Files/VcXsrv/vcxsrv.exe"
    XMING_PATH="/mnt/c/Program Files (x86)/Xming/Xming.exe"
    CYGWIN_X_PATH="/mnt/c/cygwin64/bin/XWin.exe" 

    # Initialize XSERVER_PATH variable
    XSERVER_PATH=""

    # Check if VcXsrv is installed
    if [ -f "$VCS_PATH" ]; then
        XSERVER_PATH="$VCS_PATH"
        echo "Detected VcXsrv at $VCS_PATH"
    # Or XMing
    elif [ -f "$XMING_PATH" ]; then
        XSERVER_PATH="$XMING_PATH"
        echo "Detected Xming at $XMING_PATH"
    # Check if Cygwin/X is installed
    elif [ -f "$CYGWIN_X_PATH" ]; then
        XSERVER_PATH="$CYGWIN_X_PATH"
        echo "Detected Cygwin/X at $CYGWIN_X_PATH"
    else
        echo "None of VcXsrv, Xming, or Cygwin/X is installed."
        echo "Please install one of them to proceed."
        exit 1
    fi

    # Launch Docker Desktop
    echo "Launching Docker Desktop..."
    # Using 'cmd.exe' with '/c start' to launch Windows applications from WSL/Git Bash
    cmd.exe /c start "" "C:\Program Files\Docker\Docker\Docker Desktop.exe"

    # Wait until Docker is ready
    echo "Waiting for Docker to start..."
    while ! docker system info > /dev/null 2>&1; do
        sleep 1
    done
    echo "Docker is up and running."

    # Launch the detected X11 server
    echo "Launching X11 server..."
    if [[ "$XSERVER_PATH" == "$VCS_PATH" ]]; then
        # Launch VcXsrv with desired options
        "/mnt/c/Program Files/VcXsrv/vcxsrv.exe" :0 -multiwindow -clipboard -wgl &
        XSERVER_PID=$!
    elif [[ "$XSERVER_PATH" == "$XMING_PATH" ]]; then
        # Launch Xming with desired options
        "/mnt/c/Program Files (x86)/Xming/Xming.exe" :0 -multiwindow -clipboard &
        XSERVER_PID=$!
    elif [[ "$XSERVER_PATH" == "$CYGWIN_X_PATH" ]]; then
        # Launch Cygwin/X with desired options
        "/mnt/c/cygwin64/bin/XWin.exe" :0 -multiwindow -clipboard &
        XSERVER_PID=$!
    fi

    # Wait briefly to ensure X11 server is fully started
    sleep 2

    # Allow connections from Docker containers
    echo "Configuring X11 server to allow connections from Docker..."
    xhost + 127.0.0.1

elif [[ "$PLATFORM" == "Linux" ]]; then
    # Assume X11 is already installed and running

    # Set DISPLAY environment variable if not set
    if [ -z "$DISPLAY" ]; then
        export DISPLAY=:0
        echo "DISPLAY variable not set. Defaulting to :0"
    fi

    # Allow connections from Docker containers
    echo "Configuring X11 server to allow connections from Docker..."
    # This allows connections from the local user
    xhost +local:

    # Optionally, check if Docker is running
    if ! docker system info > /dev/null 2>&1; then
        echo "Docker is not running. Please start Docker and try again."
        exit 1
    fi

else
    echo "Unsupported platform detected."
    exit 1
fi

echo "Building Docker container..."
docker build -t snid-app --progress=plain -f snid_dockerfile .

# Run the Docker container with X11 forwarding
echo "Running Docker container 'snid-app'..."

docker run -it --rm \
    --name snid-container \
    -e DISPLAY=host.docker.internal:0 \
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    -v ~/Desktop/snid:/home/sniduser/snid-5.0/desktop \
    snid-app

# Cleanup will be called automatically due to the trap

