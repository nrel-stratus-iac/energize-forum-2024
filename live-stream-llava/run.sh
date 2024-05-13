#!/bin/bash

# Description:
# This script runs the nano_llm video_query agent using Docker.
#
# Prerequisites:
# - Docker must be installed on the system.
# - NVIDIA Docker runtime must be set up.
# - The user running this script must have permissions to run Docker commands.
# - The required files and directories must exist on the system.
# - A video device must be connected and accessible at /dev/video0.
#
# Usage:
# ./run.sh

echo "Starting live streaming ..."
# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check if a device has an output
check_device_output() {
    if [ -c "$1" ]; then
        v4l2-ctl --list-formats-ext -d "$1" >/dev/null 2>&1
        return $?
    else
        return 1
    fi
}

# Check if Docker is installed
if ! command_exists docker; then
    echo "Error: Docker is not installed. Please install Docker and try again."
    exit 1
fi

# Check if NVIDIA Docker runtime is set up
if ! docker info | grep -q "Runtimes:.*nvidia"; then
    echo "Error: NVIDIA Docker runtime is not set up. Please set up the NVIDIA Docker runtime and try again."
    exit 1
fi

# Check if the user has permissions to run Docker commands
if ! docker ps >/dev/null 2>&1; then
    echo "Error: The current user does not have permissions to run Docker commands. Please grant the necessary permissions and try again."
    exit 1
fi


# Check if the video device has an output
if ! check_device_output "/dev/video0"; then
    echo "Error: The video device at /dev/video0 does not have an output. Please check the device connection and try again."
    exit 1
fi

# Create a local data directory for mounting
local_data_dir="/home/$USER/nano_llm_data"
mkdir -p "$local_data_dir"

# Run the Docker container
docker run --runtime nvidia -it --rm --network host \
    --volume /tmp/argus_socket:/tmp/argus_socket \
    --volume /etc/enctune.conf:/etc/enctune.conf \
    --volume /etc/nv_tegra_release:/etc/nv_tegra_release \
    --volume /tmp/nv_jetson_model:/tmp/nv_jetson_model \
    --volume /var/run/dbus:/var/run/dbus \
    --volume /var/run/avahi-daemon/socket:/var/run/avahi-daemon/socket \
    --volume /var/run/docker.sock:/var/run/docker.sock \
    --volume "$local_data_dir":/data \
    --device /dev/snd \
    --device /dev/bus/usb -e DISPLAY=:1 -v /tmp/.X11-unix/:/tmp/.X11-unix -v /tmp/.docker.xauth:/tmp/.docker.xauth -e XAUTHORITY=/tmp/.docker.xauth \
    --device /dev/video0 \
    --device /dev/video1 \
    dustynv/nano_llm:24.4.1-r36.2.0 \
    python3 -m nano_llm.agents.video_query --api=mlc \
    --model Efficient-Large-Model/VILA-2.7b \
    --max-context-len 768 \
    --max-new-tokens 32 \
    --video-input /dev/video0 \
    --video-output webrtc://@:8554/output