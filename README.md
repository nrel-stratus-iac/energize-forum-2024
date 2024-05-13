# Energize Forum 2024
This demonstration showcases the power of running a vision language model (VLM) directly on an edge device, the Jetson Orin Nano Developer Kit, with only 8GB of RAM. We explore the capabilities of AI/ML and IoT through real-time video analysis and local inference, eliminating the need for cloud processing. It showcases how cutting-edge technology can be leveraged in various fields including energy, smart cameras, drones, and IoT environments.  

## Hardware specs
- Device: Jetson Orin Nano Developer Kit
- GPU: 1024-core NVIDIA Ampere architecture GPU with 32 Tensor Cores
- AI performance: 40 TOPS
- CPU: 6-core Arm 64-bit CPU (1.5MB L2 + 4MB L3)
- RAM: 8GB 128-bit LPDDR5 (68 GB/s)
- Storage: 500 GB PCIe NVMe SSD as boot device
- Networking: 1x GbE Connector
- Camera: 2x MIPI CSI-2 22-pin Camera Connectors, Logitech USB Camera
- PCIe: M.2 Key M slot with x4 PCIe Gen3
- Power: 7W - 15W

### Where to buy?
You can buy the developer kit from Amazon or any of the official NVIDIA partners.  
Amazon link - https://a.co/d/1aZY6rm  
For complete list, see the [details](https://marketplace.nvidia.com/en-us/robotics-edge/) on NVIDIA's website

## Live streaming with Vision Language models
This demo utilizes a live camera feed streamed over the web using WebRTC. The VLM analyzes each frame in real-time, responding to prompts like "Describe the image concisely" or "Detect objects that are dangerous". The VLM can be used for:
- **Object Detection**: Identifying and classifying objects within the video stream.
- **Action Prediction**: Anticipating potential actions based on observed patterns.
- **Text Recognition**: Extracting and interpreting text from objects in the scene.


### How it works?

1. Video Stream: A camera feed is captured and streamed using WebRTC. We use Logitech USB camera as the input source. 
2. VLM Processing: The VILA 2.7B model, running locally on the Jetson Orin Nano, analyzes each frame and generates a response based on the given prompt.  
3. Output: The VLM's response, along with any detected objects or recognized text, is displayed on the web server hosted locally on port 8050.  You can also watch the live stream on any device connected to the same network

For more details on docker containers and scripts, check out the `live-stream-llava` directory  

### Models
We use an open source model called as ‘VILA 2.7B’ developed by MIT Han Lab and NVIDIA together. It uses OpenAI’s open source CLIP based encoder decoder architecture for video and Llama2 for text.  

It is the base model. You can download it locally from Hugging face on your device. It takes around 5-10 GB of space and can work with just 8 GB RAM. The model is quantized using Activation-aware Weight Quantization (AWQ) to enable 4-bit quantization, allowing it to run efficiently on resource-constrained devices like the Jetson Orin Nano   

## Chat with your data locally with Ollama and Open Web UI  
This part of the demo showcases Ollama, an open-source framework that allows you to run large language models (LLMs) like Llama 3 locally on your device. It bundles model weights, configuration, and data into a single package, defined by a Modelfile.  
We combine this with Open Web UI, a user-friendly interface inspired by ChatGPT, to enable interaction with the LLM. 

### How it works? 
This setup facilitates local data processing and avoids reliance on cloud-based APIs. It supports various LLM runners, including Ollama and OpenAI-compatible APIs. It provides a ChatGPT-like interface with RAG and embedding support, allowing you to load documents directly into the chat or add files to your document library. We can optimize setup and configuration details for GPU usage. It can be run on Cloud GPUs as well as local ARM CPUs via docker container and the installation is quite easy  

The open source community has also built Open AI compatible Python SDKs which makes it really easy to switch your models from using OpenAI APIs to Llama 3. You don’t need to change the underlying code

You can use any open source models that are available in the Ollama models [library](https://ollama.com/). For this demo, we have used the latest Llama 3 models from Meta and phi3 model from Microsoft as they perform slighly better than others in a series of benchmarks in Chatbot arena.  

## Visitor Presence Detection Booth Demo 
This demo parses a still snapshot produced by a camera feed, meaning the model is not continuously evaluating a video feed but is periodically evaluating a frame from the video's feed, which means the NVIDIA Jetson is not under constant load. The snapshot is parsed by the multimodal model running locally on the chip to identify how many people are visible, and the demo demonstrated the historical quantity of people in view using InfluxDB.

For more information, see [the booth demo README](booth-demo/README.md)

### How it works? 
As mentioned above, this demo uses the `VILA 2.7B` model with a hardcoded prompt asking it to identify how many people are in view, and to only return an integer response. This respond is parsed and logged to a local database for visualization as part of the demo display.



## Useful resources
1. [NVIDIA Jetson AI lab](https://www.jetson-ai-lab.com/index.html)
2. [VILA 2.7B model paper](https://hanlab.mit.edu/projects/vila)
3. [OpenAI CLIP paper](https://openai.com/index/clip)
4. [Ollama official repository](https://github.com/ollama/ollama)
5. [Open Web UI docs](https://docs.openwebui.com/)

## Acknowledgments
- NVIDIA AI and robotics research team working on Jetson AI labs
- MIT Han Lab for their work on the VILA vision language model and AWQ quantization. 
- The open-source community for developing and maintaining projects like Ollama and Open Web UI.