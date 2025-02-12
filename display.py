import requests
from PIL import Image
import io
import numpy as np
import sys
from base64 import standard_b64encode

def serialize_gr_command(**cmd):
    payload = cmd.pop('payload', None)
    cmd = ','.join(f'{k}={v}' for k, v in cmd.items())
    ans = []
    w = ans.append
    w(b'\033_G'), w(cmd.encode('ascii'))
    if payload:
        w(b';')
        w(payload)
    w(b'\033\\')
    return b''.join(ans)

def write_chunked(**cmd):
    data = standard_b64encode(cmd.pop('data'))
    while data:
        chunk, data = data[:4096], data[4096:]
        m = 1 if data else 0
        sys.stdout.buffer.write(serialize_gr_command(payload=chunk, m=m, **cmd))
        sys.stdout.flush()
        cmd.clear()

def display_image_in_terminal(image_data):
    height, width = image_data.shape[:2]
    
    if len(image_data.shape) == 3 and image_data.shape[2] == 4:
        raw_data = image_data.tobytes()
    else:
        img = Image.fromarray(image_data)
        img = img.convert("RGBA")
        raw_data = np.array(img).tobytes()

    write_chunked(a='T', f=32, s=width, v=height, data=raw_data)

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36',
    'Referer': 'https://mangakakalot.com/'
}

urls = sys.stdin.read().strip().split()
for url in urls:
    response = requests.get(url, headers=headers)
    image_bytes = response.content
    image_io = io.BytesIO(image_bytes)
    img = Image.open(image_io)
    img = img.convert("RGBA")
    np_img = np.array(img)
    display_image_in_terminal(np_img)
    print("\n")

