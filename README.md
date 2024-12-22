# Running Instructions

## Prerequisites (for OS/X)

### Required Software

1. **Docker Desktop**
   - Download from [Docker's official website](https://docs.docker.com/get-started/get-docker/)
   - Follow the installation instructions for your operating system
   - After installation, launch Docker Desktop and wait for it to fully start

2. **XQuartz**
   - Download from [XQuartz's official website](https://www.xquartz.org)
   - Install the package and restart your computer after installation
   - XQuartz is required for GUI applications in the Docker container

### XQuartz Setup

1. Launch the local Docker app and XQuartz
2. Ensure that "Allow connections from network clients" is enabled in XQuartz Preferences
3. To verify the setup, run in XQuartz terminal:
   ```bash
   xhost
   ```
   You should see:
   ```
   access control enabled, only authorized clients can connect
   127.0.0.1 being added to access control list
   ```

## Installation and Running

**Quick Start**: All the following commands are automated in the bash script `run_snid.sh`. Simply run:
```bash
./run_snid.sh
```

If you prefer to run the commands manually, follow these steps:

1. Allow Docker to Connect to XQuartz:
   ```bash
   xhost + 127.0.0.1
   ```

2. Build the Docker container:
   ```bash
   docker build -t snid-app --progress=plain -f snid_dockerfile .
   ```

3. Launch the Docker container:
   ```bash
   docker run -it --rm -e DISPLAY=host.docker.internal:0 snid-app
   ```

4. After use, revoke X server permissions:
   ```bash
   xhost - 127.0.0.1
   ```

## General Notes on Docker

### Credential Store Issues

If you encounter the error message:
```
error getting credentials - err: exec: "docker-credential-desktop": executable file not found in $PATH, out: 
```

Fix by editing `~/.docker/config.json`, changing "credsStore" to "credStore":
```json
{
    "credStore": "desktop"
}
```

**Note**: This change must be made each time Docker client restarts and overwrites the configuration file. Save the config file and restart Docker. This issue was present in older Docker versions and may appear on legacy systems (e.g., Intel architectures on older OS/X machines).

### File Transfer

#### Option 1: Using Mounted Directory
Use a mounted subdirectory in the run command (preferred method).

#### Option 2: Using Docker CP
To copy files from the container to your system:
```bash
docker cp snid-container:/home/sniduser/figures ~/Desktop/
```
Note: `docker cp` does not accept wildcards ("*"). Organize files in directories for easier transfer.

### Cleanup and Management

#### Complete Docker Cleanup
To stop running containers and clean up disk space (WARNING: this removes all Docker containers):
```bash
docker ps -q | xargs -r docker stop && \
docker ps -aq | xargs -r docker rm && \
docker images -q | xargs -r docker rmi -f && \
docker volume ls -q | xargs -r docker volume rm && \
docker builder prune -a -f && \
docker system prune -a -f
```

#### Restarting Docker Daemon on OS/X
```bash
osascript -e 'quit app "Docker"'
open /Applications/Docker.app
```
