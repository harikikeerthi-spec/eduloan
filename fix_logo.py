from PIL import Image
import os

def create_icons(source_path):
    # Open the image
    img = Image.open(source_path).convert("RGB")
    
    # 1. Manually find the bounding box of non-white pixels
    w, h = img.size
    pixels = img.load()
    
    min_x, min_y, max_x, max_y = w, h, 0, 0
    # The logo has some very light purple, so we consider everything < 245,245,245 as the logo
    for y in range(h):
        for x in range(w):
            r, g, b = pixels[x, y]
            if r < 245 or g < 245 or b < 245:
                if x < min_x: min_x = x
                if y < min_y: min_y = y
                if x > max_x: max_x = x
                if y > max_y: max_y = y

    # Catch case where image is entirely white
    if min_x >= max_x or min_y >= max_y:
        print("Could not find logo bounds.")
        return
        
    # Crop to just the exact bounds of the logo
    img_cropped = img.crop((min_x, min_y, max_x + 1, max_y + 1))
    
    # 2. Resize to fit the "Safe Zone" of Android Adaptive icons.
    # Total icon size is 1024x1024.
    # Android safe zone diameter is 1024 * (72/108) = 682 pixels.
    # We want it to be large but slightly smaller than the absolute safe zone to leave a white margin.
    # Let's use 620 pixels as the maximum dimension. This gives a visually balanced size matching Play Store.
    max_size = 620
    
    aspect = img_cropped.width / img_cropped.height
    if aspect > 1:
        new_w = max_size
        new_h = int(max_size / aspect)
    else:
        new_h = max_size
        new_w = int(max_size * aspect)
        
    img_resized = img_cropped.resize((new_w, new_h), Image.Resampling.LANCZOS)
    
    # 3. Paste onto a pure white 1024x1024 background
    final_img = Image.new("RGB", (1024, 1024), (255, 255, 255))
    offset_x = (1024 - new_w) // 2
    offset_y = (1024 - new_h) // 2
    final_img.paste(img_resized, (offset_x, offset_y))
    
    # Save as foreground (for adaptive) and square (for legacy)
    os.makedirs("assets/images", exist_ok=True)
    
    final_img.save("assets/images/app_icon_square.png", "PNG")
    # For adaptive foreground, if background is #FFFFFF, making it solid white is completely fine
    # because the launcher masks the combined result.
    final_img.save("assets/images/app_icon_foreground.png", "PNG")
    print("Icons successfully generated and saved.")

if __name__ == "__main__":
    create_icons(r"C:\Users\HP\.gemini\antigravity\brain\6256240f-3f16-464b-9744-9468885f2581\media__1773139228609.jpg")
