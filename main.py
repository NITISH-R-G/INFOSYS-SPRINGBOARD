import pytesseract
from PIL import Image
import os

pytesseract.pytesseract.tesseract_cmd = r"C:\Program Files\Tesseract-OCR\tesseract.exe"

IMAGE_PATH = r"C:\Users\NITISH\OneDrive\Pictures\Screenshots\1.png"

def main():
    if not os.path.exists(IMAGE_PATH):
        print("Error: Image file not found.")
        return

    try:
        img = Image.open(IMAGE_PATH)

        text = pytesseract.image_to_string(img)

        output_file = "output.txt"
        with open(output_file, "w", encoding="utf-8") as f:
            f.write(text)

        print("Success — text extracted to output.txt")

    except pytesseract.TesseractNotFoundError:
        print("Error — Tesseract not found.")
    except Exception as e:
        print(f"Unexpected error: {e}")

if __name__ == "__main__":
    main()
