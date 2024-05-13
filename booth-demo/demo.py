#!/usr/bin/env python3
import os 
import requests
import datetime
from time import sleep
os.environ['HF_HOME'] = os.getenv('TRANSFORMERS_CACHE')
del os.environ['TRANSFORMERS_CACHE']

from nano_llm import NanoLLM, ChatHistory
from nano_llm.utils import ArgParser, load_prompts, load_image, cuda_image

from termcolor import cprint


influx_data_post_url = f"http://localhost:8086/api/v2/write?org={os.getenv('INFLUXDB_ORG')}&bucket={os.getenv('INFLUXDB_BUCKET')}&precision=s"

influx_headers = {
    "Authorization": f"Token {os.getenv('INFLUXDB_API_TOKEN')}",
    "Content-Type": "text/plain; charset=utf-8",
    "Accept": "application/json"
}

influx_visitor_metric_template = "boothVisitors vistors={}"


# parse args and set some defaults
args = ArgParser(extras=ArgParser.Defaults + ['video_input']).parse_args()

model_prompt = "How many people are in the image? Only return an integer."
    
if not args.model:
    args.model = "Efficient-Large-Model/VILA-2.7b"

if not args.api:
    args.api = "mlc"
    
image_source = args.video_input or "/app/snapshot.png"
    

# load vision/language model
model = NanoLLM.from_pretrained(
    args.model, 
    api=args.api,
    quantization=args.quantization, 
    max_context_len=args.max_context_len,
    vision_model=args.vision_model,
    vision_scaling=args.vision_scaling, 
)

assert(model.has_vision)

chat_history = ChatHistory(model, args.chat_template, args.system_prompt)

while True:
    try:
        img = cuda_image(load_image(image_source))
    except (OSError, SyntaxError): # Ignore error read while webcam is still writing image
        continue
    finally:
        sleep(2)
    
    if img is None:
        continue

    chat_history.append(role='user', image=img)
    chat_history.append(role='user', msg=model_prompt)
    embedding, _ = chat_history.embed_chat()
    
    reply = model.generate(
        embedding,
        kv_cache=chat_history.kv_cache,
        max_new_tokens=args.max_new_tokens,
        min_new_tokens=args.min_new_tokens,
        do_sample=args.do_sample,
        repetition_penalty=args.repetition_penalty,
        temperature=args.temperature,
        top_p=args.top_p,
    )
    
    reply_string_raw = ' '.join(token for token in reply)
    reply_string = reply_string_raw.partition(r'</s>')[0]
    timestamp = datetime.datetime.now().strftime('%H:%M:%S')
    
    cprint(f"{timestamp}>> {model_prompt} ", 'blue', end='', flush=True)
    try:
        parsed_number = int(reply_string)
        requests.post(influx_data_post_url,
                        headers=influx_headers,
                        data=influx_visitor_metric_template.format(parsed_number))
        print(parsed_number)
    except ValueError:
        print(reply_string)
        pass

    chat_history.append(role='bot', text=reply.text)
    chat_history.kv_cache = reply.kv_cache
    chat_history.reset()