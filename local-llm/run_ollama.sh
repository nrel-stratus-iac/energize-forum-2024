# Description:
# This script starts the Open Web UI application using Docker.
#
# Prerequisites:
# - Docker must be installed on the system.
# - NVIDIA Docker runtime must be set up.
# - The user running this script must have permissions to run Docker commands.
# - The required files and directories must exist on the system.
#
# Usage:
# ./run_ollama.sh

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
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

# Create a local directory for mounting ollama models

local_dir="/home/$USER/ollama_data"
mkdir -p "$local_dir"

echo "Starting Open Web UI application..."

# Run the Docker container
docker run --runtime nvidia -it --rm --network host \
    --volume /tmp/argus_socket:/tmp/argus_socket \
    --volume /etc/enctune.conf:/etc/enctune.conf \
    --volume /etc/nv_tegra_release:/etc/nv_tegra_release \
    --volume /tmp/nv_jetson_model:/tmp/nv_jetson_model \
    --volume /var/run/dbus:/var/run/dbus \
    --volume /var/run/avahi-daemon/socket:/var/run/avahi-daemon/socket \
    --volume /var/run/docker.sock:/var/run/docker.sock \
    --volume "$local_dir":/data \
    --device /dev/snd --device /dev/bus/usb -e DISPLAY=:1 -v /tmp/.X11-unix/:/tmp/.X11-unix -v /tmp/.docker.xauth:/tmp/.docker.xauth -e XAUTHORITY=/tmp/.docker.xauth \
    --detach \
    --name ollama dustynv/ollama:r36.2.0

if [ $? -eq 0 ]; then
    echo "Open Web UI application started successfully."
else
    echo "Error: Failed to start the Open Web UI application. Please check the Docker logs for more information."
    exit 1
fi