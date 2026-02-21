import os
import sys
sys.path.append(r'C:\Users\nitis\AppData\Roaming\Python\Python314\site-packages')
from dotenv import load_dotenv
import google.generativeai as genai

# Test 1: Check Tesseract
print("--- Test 1: Tesseract Path ---")
tesseract_cmd = r"C:\Program Files\Tesseract-OCR\tesseract.exe"
found = False

if os.path.exists(tesseract_cmd):
    print(f"[SUCCESS] Tesseract found at: {tesseract_cmd}")
    found = True
else:
    # Try common paths
    common_paths = [
        r"C:\Program Files (x86)\Tesseract-OCR\tesseract.exe",
        os.path.expandvars(r"%LOCALAPPDATA%\Programs\Tesseract-OCR\tesseract.exe"),
        os.path.expandvars(r"%LOCALAPPDATA%\Tesseract-OCR\tesseract.exe"),
    ]
    for path in common_paths:
        if os.path.exists(path):
            print(f"[SUCCESS] Tesseract found at: {path}")
            found = True
            break

if not found:
    print("[FAIL] Tesseract NOT found in common locations.")

# Test 2: Check API Key and Model
print("\n--- Test 2: Gemini API & Model Use ---")
load_dotenv()
api_key = os.getenv("GEMINI_API_KEY")

if not api_key:
    print("[FAIL] GEMINI_API_KEY not found in environment.")
else:
    print(f"[INFO] API Key found: {api_key[:5]}...{api_key[-5:]}")
    genai.configure(api_key=api_key)
    
    models_to_try = ['gemini-2.0-flash', 'gemini-flash-latest']
    model_working = False
    
    for model_name in models_to_try:
        print(f"\n[INFO] Testing model: {model_name}")
        try:
            model = genai.GenerativeModel(model_name)
            response = model.generate_content("Hello, reply with 'OK' if you can hear me.")
            print(f"[SUCCESS] Model {model_name} response: {response.text.strip()}")
            model_working = True
            break
        except Exception as e:
            print(f"[FAIL] Model {model_name} generation failed: {e}")
            
    if not model_working:
        print("\n[FAIL] All tested models failed.")
