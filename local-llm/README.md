## Instructions 
1. Run the `local-llm/run_ollama.sh` script to start a docker container with nvidia runtime. It takes roughly about 5-10 minutes to pull the Ollama container
2. Now exec it into the container using the command `docker exec -it <container-id> bash`
3. Download the models locally inside the container using the command `ollama pull <model-name>`. For a full list of models, go to Ollama models [library](https://ollama.com/library). 
4. Once the container is up and running, the local Ollama service will listen on port 11434. It also exposes an endpoint locally that we can use to interact with a model. 
5. Now download and install the Open Web UI application by running the `local-llm/run_openwebui.sh` script. It will first pull the official docker image locally on the Jetson, mount the host file system inside the container to persist data and then start a webserver on port 8080
6. Navigate to `http://<IP_ADDRESS>:8080` and create your account. 
7. Once the account is setup, select the model that you downloaded with Ollama and start chatting with the LLM  

** TODO** Add screenshots