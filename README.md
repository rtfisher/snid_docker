# SNID-Docker

This short Docker file uses a containerized approach to easily enable running the SuperNova IDentification code (Blondin & Tonry, 2007, Tonry & Davis, 1979) on any platform. The requisite PGPLOT library including the X-Windows interface is automatically downloaded and installed inside a Linux container. SNID is configured and built on top of PGPLOT. The container hosts an X11 server which the user can easily connect to via a local X11 client on their desktop. All of this is accomplished by executing a single script, `run_snid.sh`, which automatically detects system architecture and launches Docker and the X11 client. 

![SNID Docker Running on OS/X.](/_images/snid_sn2003jo.png)

_References:_

"Determining the Type, Redshift, and Age of a Supernova Spectrum" 
Blondin, S. & Tonry, J. L. 2007. ApJ, 666, 1024

"A survey of galaxy redshifts. I - Data reduction techniques"
Tonry, J. L. & Davis, M. 1979. AJ, 84, 1511

# Running Instructions

## Prerequisites 

### Required Software

1. **Docker Desktop**
   - Download and install [Docker](https://docs.docker.com/get-started/get-docker/).

2. **SNID and Template Library**
   - Download the gzipped tarballs snid-5.0.tar.gz and templates-2.0.tgz from Stéphane Blondin's website [https://people.lam.fr/blondin.stephane/software/snid/]. Store these in the same local working directory where you have cloned this github repo.
   
3. **An X11 Client** 
   - MacOS: Download and install [XQuartz](https://www.xquartz.org).
   - Windows: Download and install either [VcXsrv](https://vcxsrv.com/), [XMing](https://sourceforge.net/projects/xming/), or [Cygwin/X](https://cygwin.com/install.html). Note Cygwin/X is part of the larger Cygwin project.
   - Linux: X11 is installed as part of most Linux distros. You can verify by simply typing ```startx``` in a terminal. If X11 is not installed, you can install it using the relevant package manager on your system. For example:
      - ```sudo apt install xorg```(Debian/Ubuntu)
      - ```sudo dnf install xorg-x11-server-Xorg xorg-x11-xinit xorg-x11-apps``` (Red Hat/CentOS/Fedora)
      - ```sudo pacman -S xorg-server xorg-apps xorg-xinit``` (Arch Linux)
      - ```sudo zypper install xorg-x11-server xorg-x11-xinit xterm``` (openSUSE)

4. **This Github Repo**
   - In the terminal, run ```git clone https://github.com/rtfisher/snid_docker```.

   
### X11 Configuration

The X11 configuration process is straightforward, but differs depending on your operating system and X11 client. Begin by launching the Docker application and your X11 client.


#### macOS: XQuartz Setup

1. **Configure XQuartz**
   - In the menu bar, click on `XQuartz` → `Preferences`.
   - Navigate to the `Security` tab.
   - **Check** the box labeled **"Allow connections from network clients"**.
   - **Apply** the changes and restart XQuartz if prompted.


#### Windows ####

Option 1. **VcXsrv**
   - Launch **VcXsrv** using the **XLaunch** wizard:
     - **Display Settings:**
       - **Multiple windows**
       - **Display number:** `0`
     - **Client Startup:**
       - **Start no client**
     - **Additional Settings:**
       - **Enable clipboard**
       - **Enable OpenGL** (if required)
     - **Finish** to start the server.


Option 2. **Cygwin/X**
   - Launch **Cygwin/X** by executing the `startx` command in the Cygwin terminal:
     ```bash
     startx
     ```

     
#### Linux ####

1. **Launch Docker**
   - Ensure that Docker is installed and running on your Linux distribution.
   - Open your terminal and start Docker if it's not already running:
     ```bash
     sudo systemctl start docker
     ```



### Configuring X11 and Verifying X11 Setup


2. **Configure X11 Server Permissions**

   - Allow loopback connections from Docker containers:
     ```bash
     xhost + 127.0.0.1
     ```

3. **Verify the Setup**
   - Run the following command to verify that permissions are correctly set:
     ```bash
     xhost
     ```
   - **Expected Output:**
     ```
     access control enabled, only authorized clients can connect
     127.0.0.1 being added to access control list
     ```


## Quick Start

All of the necessary commands to build and run the Docker container are automated in the bash script `run_snid.sh`. Simply open a terminal and cd to the directory storing this github repo and run:
```bash
./run_snid.sh
```

If all proceeds fine, you will see some output similar to 
```
Configuring XQuartz to allow connections from Docker...
127.0.0.1 being added to access control list
Running Docker container 'snid-app'...
sniduser@4585bce060da:~/snid-5.0$
```
Following this, you will be dropped into the container. To verify SNID is functioning correctly, you can run

```./snid examples/sn2003jo.dat ```

An interactive window similar to the one above should display.

## Manual Container Building and Launching

If you prefer to build and launch the container by hand, follow these steps:

1. Allow Docker to connect to X11 client via loopback:
   ```bash
   xhost + 127.0.0.1
   ```

2. Build the Docker container:
   ```bash
   docker build -t snid-app --progress=plain -f snid_dockerfile .
   ```

3. Launch the Docker container:
   ```bash
     docker run -it --rm \
         -e DISPLAY=$DISPLAY \
         -v /tmp/.X11-unix:/tmp/.X11-unix \
         snid-app
   ```

4. After use, revoke X server permissions:
   ```bash
   xhost - 127.0.0.1
   ```

## General Notes on Docker

### Credential Store Known Issue

If you encounter the error message:
```
error getting credentials - err: exec: "docker-credential-desktop": executable file not found in $PATH, out: 
```

This is a known issue which you can easily fix by editing `~/.docker/config.json`, changing "credsStore" to "credStore":
```json
{
    "credStore": "desktop"
}
```

**Note**: This change must be made each time Docker client restarts and overwrites the configuration file. Save the config file and restart Docker. This issue was present in older Docker versions and may appear on legacy systems (e.g., Intel architectures on older OS/X machines).

### File Transfer

#### Option 1: Using Mounted Directory
The easiest way to transfer files from within the container back to the system is by using a directory mount. SNID-Docker mounts the container directory `desktop` to the directory `snid` on your system desktop. Any files you copy into the `desktop` folder in the container will automatically be copied to the `snid` folder and persist even after the Docker container is shut down. Similarly, any system files which are copied to `snid` on your system desktop will automatically appear within the mounted `desktop` folder in the container.

#### Option 2: Using Docker cp
To copy files from a subdirectory in the container to your system desktop, you could run:
```bash
docker cp snid-container:/home/sniduser/figures ~/Desktop/
```
Here the folder `figures` is being copied from the home directory of the container. Note: `docker cp` does not accept wildcards ("*"). Organize files in directories for easier transfer.

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
Very rarely you may need to restart the Docker daemon. On OS/X:
```bash
osascript -e 'quit app "Docker"'
open /Applications/Docker.app
```
