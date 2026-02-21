
import os
import google.generativeai as genai
from dotenv import load_dotenv

# Load .env explicitly
load_dotenv()

api_key = os.getenv("GEMINI_API_KEY")
print(f"Loaded API Key: {api_key[:10]}...{api_key[-5:] if api_key else 'None'}")

if not api_key:
    print("Error: No API Key found.")
    exit(1)

genai.configure(api_key=api_key)

try:
    print("Attempting to list models...")
    for m in genai.list_models():
        if 'generateContent' in m.supported_generation_methods:
            print(f"Found model: {m.name}")
            
    print("\nAttempting to generate content with 'gemini-2.0-flash'...")
    model = genai.GenerativeModel('gemini-2.0-flash')
    response = model.generate_content("Hello")
    print(f"Success! Response: {response.text}")
    
except Exception as e:
    print(f"Error: {e}")
