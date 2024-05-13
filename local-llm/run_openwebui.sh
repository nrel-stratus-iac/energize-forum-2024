# Description:
# This script starts the Open Web UI application using Docker and creates a new volume.
#
# Prerequisites:
# - Docker must be installed on the system.
# - The user running this script must have permissions to run Docker commands.
#
# Usage:
# ./run_openwebui.sh

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check if a Docker container is running
is_container_running() {
    docker ps --format '{{.Names}}' | grep -q "^$1$"
}

# Check if Docker is installed
if ! command_exists docker; then
    echo "Error: Docker is not installed. Please install Docker and try again."
    exit 1
fi

# Check if the user has permissions to run Docker commands
if ! docker ps >/dev/null 2>&1; then
    echo "Error: The current user does not have permissions to run Docker commands. Please grant the necessary permissions and try again."
    exit 1
fi

# Set the name of the Docker container
container_name="open-webui"

# Check if the Docker container is already running
if is_container_running "$container_name"; then
    echo "The Open Web UI container is already running. Stopping and removing the existing container..."
    docker stop "$container_name"
    docker rm "$container_name"
fi

# Run the Docker container
echo "Starting the Open Web UI application..."
docker run -d --network=host --add-host=host.docker.internal:host-gateway \
    -v open-webui:/app/backend/data \
    --name "$container_name" \
    --restart always \
    ghcr.io/open-webui/open-webui:main

# Check if the Docker container started successfully
if is_container_running "$container_name"; then
    echo "The Open Web UI application started successfully."
else
    echo "Error: Failed to start the Open Web UI application. Please check the Docker logs for more information."
    exit 1
fi