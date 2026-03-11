import os
from PIL import Image, ImageOps

def resize_logo(input_path, output_path, size=512, padding_ratio=0.15):
    """
    Trims whitespace from a logo and re-centers it on a square canvas with padding.
    """
    try:
        if not os.path.exists(input_path):
            print(f"Error: {input_path} not found.")
            return

        img = Image.open(input_path).convert("RGBA")
        
        # 1. Trim whitespace
        # Get the bounding box of non-transparent (or non-white) pixels
        # We'll treat very light pixels as "white" if alpha is 255
        # but better to just use alpha channel if possible
        alpha = img.split()[-1]
        bbox = alpha.getbbox()
        
        if not bbox:
            print("Error: Image is fully transparent.")
            return

        trimmed_img = img.crop(bbox)
        
        # 2. Add padding and center on square canvas
        w, h = trimmed_img.size
        # Determin which is larger to make a square
        max_dim = max(w, h)
        
        # Calculate target size for the logo inside the square
        # We want the logo to occupy (1 - 2*padding_ratio) of the canvas
        internal_size = int(size * (1 - 2 * padding_ratio))
        
        # Scale the logo while keeping aspect ratio
        ratio = internal_size / max_dim
        new_w, new_h = int(w * ratio), int(h * ratio)
        resized_logo = trimmed_img.resize((new_w, new_h), Image.LANCZOS)
        
        # Create final square canvas
        final_img = Image.new("RGBA", (size, size), (255, 255, 255, 0)) # Transparent background
        
        # Center the logo
        offset = ((size - new_w) // 2, (size - new_h) // 2)
        final_img.paste(resized_logo, offset, resized_logo)
        
        # Save as PNG
        final_img.save(output_path, "PNG")
        print(f"Successfully processed logo: {output_path}")

    except Exception as e:
        print(f"Failed to process logo: {e}")

if __name__ == "__main__":
    logo_path = r"c:\flutter\projects\eduloan\assets\images\app_icon_square.png"
    resize_logo(logo_path, logo_path) # Overwrite with processed version
