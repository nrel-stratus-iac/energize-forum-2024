#!/usr/bin/env bash
export NREL_DEMO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export INFLUXDB_ORG=NREL
export INFLUXDB_BUCKET=demo
export INFLUXDB_API_TOKEN=admintokensecret

cd "$NREL_DEMO_DIR"

python -m http.server 8080 &>/dev/null & disown

guvcview \
    --device /dev/video0 \
    --resolution=960x720 \
    --image=$NREL_DEMO_DIR/snapshot.png \
    --photo_total=0 \
    --photo_timer=2 \
    --fps 5 \
    --audio=none \
    --gui=none & disown
	
docker run --rm -d \
    --name=influxdb \
    -p 8086:8086 \
    -v "$NREL_DEMO_DIR/influx/data:/var/lib/influxdb2" \
    -v "$NREL_DEMO_DIR/influx/config:/etc/influxdb2" \
    -e INFLUXD_SESSION_LENGTH=9999 \
    -e DOCKER_INFLUXDB_INIT_MODE='setup' \
    -e DOCKER_INFLUXDB_INIT_USERNAME='admin' \
    -e DOCKER_INFLUXDB_INIT_PASSWORD='adminadmin' \
    -e DOCKER_INFLUXDB_INIT_ORG=$INFLUXDB_ORG \
    -e DOCKER_INFLUXDB_INIT_BUCKET=$INFLUXDB_BUCKET \
    -e DOCKER_INFLUXDB_INIT_RETENTION='1w' \
    -e DOCKER_INFLUXDB_INIT_ADMIN_TOKEN=$INFLUXDB_API_TOKEN \
    -- influxdb:2.7.6

/usr/local/bin/jetson-containers run \
    -v $NREL_DEMO_DIR:/app \
    -e INFLUXDB_ORG=$INFLUXDB_ORG \
    -e INFLUXDB_BUCKET=$INFLUXDB_BUCKET \
    -e INFLUXDB_API_TOKEN=$INFLUXDB_API_TOKEN \
    $(/usr/local/bin/autotag nano_llm:24.4.1-r36.2.0) python3 /app/main.py