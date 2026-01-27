import sys
import os
from PIL import Image

def process_logos(input_path, output_dir):
    try:
        if not os.path.exists(output_dir):
            os.makedirs(output_dir)

        im = Image.open(input_path)
        im = im.convert("RGBA")
        width, height = im.size
        print(f"Image size: {width}x{height}")

        # Strategy: Scan for vertical whitespace columns to identify segments
        # We assume white or transparent background
        
        # 1. Identify active columns (columns that are NOT fully white/transparent)
        active_cols = []
        for x in range(width):
            is_active = False
            for y in range(height):
                r, g, b, a = im.getpixel((x, y))
                # Check if pixel is NOT white/transparent
                # White is (255,255,255), Transparent has alpha 0
                if a > 0 and (r < 250 or g < 250 or b < 250):
                    is_active = True
                    break
            if is_active:
                active_cols.append(x)

        if not active_cols:
            print("No active content found!")
            return

        # 2. Group active columns into segments
        segments = []
        if active_cols:
            start = active_cols[0]
            prev = active_cols[0]
            for col in active_cols[1:]:
                if col > prev + 10: # If gap is larger than 10 pixels, new segment
                    segments.append((start, prev))
                    start = col
                prev = col
            segments.append((start, prev))

        print(f"Found {len(segments)} segments: {segments}")

        # 3. Crop and Save
        # Expected order: Auxilo, Avanse, Credila
        names = ["auxilo_logo_final.png", "avanse_logo_final.png", "credila_logo_final.png"]
        
        for i, (start, end) in enumerate(segments):
            if i >= len(names):
                break
            
            # Add some padding
            left = max(0, start - 10)
            right = min(width, end + 10)
            
            # Crop to the segment width, full height (then trim height)
            crop = im.crop((left, 0, right, height))
            
            # Trim vertical whitespace
            bbox = crop.getbbox()
            if bbox:
                crop = crop.crop(bbox)
            
            out_path = os.path.join(output_dir, names[i])
            crop.save(out_path)
            print(f"Saved {names[i]} to {out_path}")

    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    # Hardcoded paths based on user session context
    input_image = r"C:\Users\HP\.gemini\antigravity\brain\a2e11f04-bc9f-4f04-88ac-b09150d45df5\uploaded_media_1769502785274.png"
    output_directory = r"c:\flutter\projects\eduloan\assets\images"
    process_logos(input_image, output_directory)
