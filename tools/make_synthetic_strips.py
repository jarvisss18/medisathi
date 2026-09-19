import os
import sys

def create_synthetic_images():
    output_dir = os.path.join(os.path.dirname(__file__), "..", "mobile", "assets", "demo", "synthetic")
    os.makedirs(output_dir, exist_ok=True)

    try:
        from PIL import Image, ImageDraw, ImageFont, ImageFilter
    except ImportError:
        print("PIL / Pillow not installed. Creating placeholder PNG/JPG files...")
        # Create minimal 100x100 RGB image files if PIL missing
        for filename in [
            "strip_paracetamol_500mg.jpg",
            "strip_paracetamol_blurry.jpg",
            "strip_amlodipine_no_mg.jpg",
            "strip_unknown.jpg"
        ]:
            path = os.path.join(output_dir, filename)
            with open(path, "wb") as f:
                f.write(b'\xFF\xD8\xFF\xE0\x00\x10JFIF\x00\x01\x01\x01\x00`\x00`\x00\x00\xFF\xDB\x00C\x00\x08\x06\x06\x07\x06\x05\x08\x07\x07\x07\t\t\x08\n\x0c\x14\r\x0c\x0b\x0b\x0c\x19\x12\x13\x0f\x14\x1d\x1a\x1f\x1e\x1d\x1a\x1c\x1c $.\' ",#\x1c\x1c(7),01444\x1f\'9=82<.342\xFF\xC0\x00\x0b\x08\x00\x10\x00\x10\x01\x01\x11\x00\xFF\xC4\x00\x1f\x00\x00\x01\x05\x01\x01\x01\x01\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x01\x02\x03\x04\x05\x06\x07\x08\t\n\x0b\xFF\xDA\x00\x08\x01\x01\x00\x00?\x00\x7F\x00\xFF\xD9')
        print(f"Placeholder images generated in {output_dir}")
        return

    # Image specifications
    specs = [
        {
            "filename": "strip_paracetamol_500mg.jpg",
            "text": "Paracetamol Tablets IP\n500 mg\nBatch: B9876\nExp: 10/28",
            "bg": (240, 240, 245),
            "fg": (20, 20, 30),
            "blur": False
        },
        {
            "filename": "strip_paracetamol_blurry.jpg",
            "text": "Paracetamol Tablets IP\n500 mg\nBatch: B9876",
            "bg": (240, 240, 245),
            "fg": (20, 20, 30),
            "blur": True
        },
        {
            "filename": "strip_amlodipine_no_mg.jpg",
            "text": "Amlodipine Tablets IP\nKeep out of reach of children\nBatch: AML123",
            "bg": (250, 245, 235),
            "fg": (30, 20, 20),
            "blur": False
        },
        {
            "filename": "strip_unknown.jpg",
            "text": "Random Vitamin Compound\nXYZ 1000 IU\nNutritional Supplement",
            "bg": (235, 250, 235),
            "fg": (10, 40, 10),
            "blur": False
        },
    ]

    for spec in specs:
        img = Image.new("RGB", (600, 400), color=spec["bg"])
        draw = ImageDraw.Draw(img)

        # Draw a simulated foil strip border
        draw.rectangle([20, 20, 580, 380], outline=(180, 180, 190), width=4)
        
        # Add text
        try:
            font = ImageFont.load_default()
        except Exception:
            font = None

        draw.multiline_text((40, 60), spec["text"], fill=spec["fg"], font=font, spacing=12)

        if spec["blur"]:
            img = img.filter(ImageFilter.GaussianBlur(radius=8))

        save_path = os.path.join(output_dir, spec["filename"])
        img.save(save_path, quality=90)
        print(f"Generated {save_path}")

if __name__ == "__main__":
    create_synthetic_images()
