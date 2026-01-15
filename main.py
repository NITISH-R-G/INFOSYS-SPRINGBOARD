import pytesseract
from PIL import Image
import os

# 1. SET YOUR TESSERACT PATH HERE
# Ensure this points to where you actually installed Tesseract
pytesseract.pytesseract.tesseract_cmd = r"C:\Program Files\Tesseract-OCR\tesseract.exe"

def main():
    print("--- OCR Text Extractor ---")
    
    # 2. PROMPT FOR USER INPUT
    image_path = input("Please enter or paste the full image file path: ").strip()

    # Remove quotes if the user copied the path with them (e.g., "C:\path\file.png")
    image_path = image_path.replace('"', '').replace("'", "")

    # Check if the path is valid
    if not os.path.exists(image_path):
        print(f"Error: The file '{image_path}' was not found. Please check the path and try again.")
        return

    try:
        print("Processing image... please wait.")
        
        # Load the image
        img = Image.open(image_path)
        
        # Perform OCR
        text = pytesseract.image_to_string(img)
        
        # Determine output filename (saves in the same folder as the script)
        base_name = os.path.splitext(os.path.basename(image_path))[0]
        output_file = f"{base_name}_extracted.txt"
        
        # Save text to file
        with open(output_file, "w", encoding="utf-8") as f:
            f.write(text)
            
        print("-" * 30)
        print(f"Success! Text extracted to: {os.path.abspath(output_file)}")
        print("-" * 30)
        
    except Exception as e:
        print(f"\n[ERROR]: {e}")
        print("Tip: Make sure Tesseract is installed and the path at the top of this script is correct.")

if __name__ == "__main__":
    main()
