## Instructions
1. Connect a camera to the Jetson Orin Nano. Check the device output using the command `lsusb` if you're using a USB camera. If you're using CSI MIPI camera sensors like IMX 219, then you need to change the video input from `/dev/video0` to `csi://0`
2. Run the `live-stream-llava/run.sh` script to start a docker container with nvidia runtime. It takes roughly about 10-20 minutes to pull the container, download the models, mount the volumes and devices inside the container. 
3. Once the container is up and running, it will start the live streaming and inference pipeline.  
4. Access the web interface to view the live stream and interact with the vision language model.
5. The LLM agent applies prompts to the incoming video feed with the VLM. Navigate your browser to https://<IP_ADDRESS>:8050 after launching it with your camera (Chrome is recommended with chrome://flags#enable-webrtc-hide-local-ips-with-mdns disabled)
6. Customize the prompts to query the model based on your requirements (e.g., object detection, action prediction, text reading).

** TODO** Add screenshots