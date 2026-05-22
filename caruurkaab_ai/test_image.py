from PIL import Image
import sys

try:
    img = Image.open('/Users/macbook/.gemini/antigravity/brain/3339802f-aa93-4163-b15c-3cd84b8fe41b/media__1779136054781.jpg')
    print(f"Original size: {img.width}x{img.height}")
except Exception as e:
    print(e)
