# NREL Energize Forum 2024 Interactive Edge AI Booth Demo
<sub>Demo created by [Michael Bartlett](https://research-hub.nrel.gov/en/persons/michael-bartlett), adapated from the [Nano_LLM multimodal video querying tutorials](https://www.jetson-ai-lab.com/tutorial_nano-vlm.html)</sub>

## Hardware setup

This setup uses the [Nano_LLM library](https://www.jetson-ai-lab.com/tutorial_nano-llm.html) which requires the user to flash [JetPack version 6.0](https://developer.nvidia.com/embedded/jetpack-sdk-60) using the [NVIDIA SDK Manager](https://docs.nvidia.com/sdk-manager/install-with-sdkm-jetson/index.html).

The simplest way I found in my experience was to flash an [.iso of Ubuntu 20](https://www.releases.ubuntu.com/focal/) to a USB and use it to liveboot into an ephemeral session of Ubuntu. Then, follow the instructions for the NVIDIA SDK Manager flashing process. Flashing the Nano this way took around 30 minutes. It's recommended to have an NVMe SSD with several hundred gigabytes of storage space to hold the OS, the NVIDIA drivers, and the models. The NVIDIA SDK Manager allows one to flash the OS directly to the NVMe storage and avoid needing to use a microSD card.

## Operating system setup

Once the Jetson OS boots, install the following Debian packages using the `apt` package manager or the "Software" GUI app:

* docker (docker containers are the primary means that Nano_LLM distributes its library)
* guvcview (this is a basic webcam viewer that supports V4L2 driver controls to control the camera hardware)

After installing docker you may need to enable and start its background process service:
```console
$ sudo systemctl enable docker
$ sudo systemctl start docker
```

Next, clone the `jetson-containers` git repo here: <https://github.com/dusty-nv/jetson-containers>

Once you have the code repository downloaded, follow the installation instructions here: <https://github.com/dusty-nv/jetson-containers?tab=readme-ov-file#getting-started>


I also strongly recommend following the recommendations here to enable a swapfile and free up the Jetson's RAM to avoid memory-full errors: <https://github.com/dusty-nv/jetson-containers/blob/master/docs/setup.md#mounting-swap>


Finally, test that everything is installed correctly by executing a session within a jetson container using the Nano_LLM container version `24.4.1-r36.2.0` which is the version I used for this demo:
```console
$ /usr/local/bin/jetson-containers run $(/usr/local/bin/autotag nano_llm:24.4.1-r36.2.0) bash
Namespace(packages=['nano_llm:24.4.1-r36.2.0'], prefer=['local', 'registry', 'build'], disable=[''], user='dustynv', output='/tmp/autotag', quiet=False, verbose=False)
-- L4T_VERSION=36.3.0  JETPACK_VERSION=6.0  CUDA_VERSION=12.2
-- Finding compatible container image for ['nano_llm:24.4.1-r36.2.0']
dustynv/nano_llm:24.4.1-r36.2.0
+ sudo docker run --runtime nvidia -it --rm --network host --volume /tmp/argus_socket:/tmp/argus_socket --volume /etc/enctune.conf:/etc/enctune.conf --volume /etc/nv_tegra_release:/etc/nv_tegra_release --volume /tmp/nv_jetson_model:/tmp/nv_jetson_model --volume /var/run/dbus:/var/run/dbus --volume /var/run/avahi-daemon/socket:/var/run/avahi-daemon/socket --volume /var/run/docker.sock:/var/run/docker.sock --volume /home/jetson/Documents/jetson-containers/data:/data --device /dev/snd --device /dev/bus/usb -e DISPLAY=:1 -v /tmp/.X11-unix/:/tmp/.X11-unix -v /tmp/.docker.xauth:/tmp/.docker.xauth -e XAUTHORITY=/tmp/.docker.xauth --device /dev/video0 --device /dev/video1 --device /dev/video2 --device /dev/video3 -v /home/jetson/Documents/nano_vlm:/app dustynv/nano_llm:24.4.1-r36.2.0 bash

# python3 -m nano_llm -h
usage: __main__.py [-h] [--model MODEL] [--quantization QUANTIZATION]
                   [--api {auto_gptq,awq,hf,mlc}]
                   [--vision-model VISION_MODEL]
                   [--vision-scaling {crop,resize}] [--prompt [PROMPT ...]]
                   [--save-mermaid SAVE_MERMAID]
...
```

If the container is setup correctly, the `nano_llm` python module should be accessible from the container's main python interpretter. If this is working, proceed to the next section which explains how to run this demo application which uses the multimodal vision+chat model to ask the model to count the number of people in the view of a webcam attached to the Jetson Nano Orin.


## Run the demo

### Clone this repository to the Jetson Orin Nano


```sh
git clone https://github.nrel.gov/nrel-cloud-computing/energize-forum-2024
cd energize-forum-2024/booth-demo
```

### Variables

First, let's define some runtime variables that will be reused:

```sh
export NREL_DEMO_DIR="$PWD"
export INFLUXDB_ORG=NREL
export INFLUXDB_BUCKET=demo
export INFLUXDB_API_TOKEN=admintokensecret
```

Make sure the `NREL_DEMO_DIR` variable contains the path to the `energize-forum-2024/booth-demo` where this README is located.

### Start webcam image stream

Now, make sure that the `guvcview` application works and can show a preview from the camera attached to your Jetson. Note that native camera models exist for the Jetson Orin Nano's devkit board, but I am using an external webcam which requires using a USB-hub with its own power supply as the external webcam may draw too much power from the Jetson and cause the USB ports to be power throttled and stop the webcam from functioning.

Simply running `guvcview` from the terminal or launching it from the Jetson GUI's application menu should launch the software with its configuration menu and webcame view window. If it does not display any errors, then it should be safe to continue.

Within this demo, I use `guvcview` to produce a still image every 2 seconds, but the preview window refreshes multiple times a second to make it easier to orient the camera as desired and get faster feedback. The Nano_LLM model will simply read the same image file on a loop, but `guvcview` will overwrite that image file every 2 seconds.

To accomplish this, take a note of the device file that your webcome is mounted as (this can most easily be identified from the output of running `guvcview` in a terminal). There's a good chance it will be `/dev/video0` if you only have a single camera attached.

If you haven't executed `guvcview` yet, please run it so that it creates a configuration file for your camera. We will need to edit this file. It will write a configuration file for each video device file that it reads as a source. So in my case, the configuration file to edit will be in `~/.config/guvcview2/video0`. Look for the configuration option named `photo_sufix`, and change it to be off by replacing the entire line with `photo_sufix=0` and saving this file. This step is necessary to make `guvcview` overwrite the same image file instead of creating multiple image files with an increasing number suffix.

With that in place, here is a sample call to `guvcview` that only shows the camera preview window which allows me to see and control the camera's orientation using its builtin motors:

```sh
guvcview \
    --device /dev/video0 \
    --resolution=960x720 \
    --image=$NREL_DEMO_DIR/snapshot.png \
    --photo_total=0 \
    --photo_timer=2 \
    --fps 5 \
    --audio=none \
    --gui=none
```

Perhaps the most important arguments here are the `--image` flag which instructs the application where to save images, and the `--photo_total=0` argument which instructs the application to take new photos indefinitely. `--photo_timer=2` will make the application take a new photo every 2 seconds, which is sufficient for the demo and avoids the Jetson being under constant load.

With your webcam image being updated continuously, it's time to invoke the rest of the stack

### Start a basic HTTP server
This is mainly for the InfluxDB Dashboard to access the QR code image locally at `http://localhost:8080/snapshot.png`. We hide its output and launch it in the background so we can continue using the same shell.

```sh
cd $NREL_DEMO_DIR
python -m http.server 8080 &>/dev/null & disown
```

### Run the InfluxDB container with initial values and persistent storage

```sh
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
```

Once this command runs, the InfluxDB container will be running in the background. Go to <http://localhost:8086> on your machine and login with the username and password shown in the environment variables above.

I launch the Influx HTTP server in kiosk mode like so:
```
chromium --app=http://localhost:8086
```


### Run the inference model

Finally, we invoke the `jetson-containers` nano_llm image like above and run the VILA model against our snapshots and ask it to summarize how many people are in view.

This code will read the image being overwritten by `guvcview` every few seconds and perform an inference on the image. In this demo, the hard-coded prompt is asking the model to identify how many people are in the image and returning only an integer as a response. The integer is then written to InfluxDB under the `boothVisitors` database and the `visitors` metric. For this model to work we will need InfluxDB running and `guvcview` writing its video feed to the image `$NREL_DEMO_DIR/snapshot.png`. 

Here we export the necessary environment variables for the code to authenticate to InfluxDB and we also bind this repository as a volume inside the container found at `/app`.

```sh
/usr/local/bin/jetson-containers run \
    -v $NREL_DEMO_DIR:/app \
    -e INFLUXDB_ORG=$INFLUXDB_ORG \
    -e INFLUXDB_BUCKET=$INFLUXDB_BUCKET \
    -e INFLUXDB_API_TOKEN=$INFLUXDB_API_TOKEN \
    $(/usr/local/bin/autotag nano_llm:24.4.1-r36.2.0) python3 /app/main.py
```
