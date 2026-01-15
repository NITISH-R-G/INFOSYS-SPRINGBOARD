import os
import pytesseract
from PIL import Image
import google.generativeai as genai
from dotenv import load_dotenv
from fastapi import FastAPI, UploadFile, File, HTTPException
from pydantic import BaseModel
from pathlib import Path
import io

# 1. Configuration
# Load environment variables explicitly from .env in the same directory
env_path = Path(__file__).parent / '.env'
load_dotenv(dotenv_path=env_path)

# Set Tesseract Path
pytesseract.pytesseract.tesseract_cmd = r"C:\Program Files\Tesseract-OCR\tesseract.exe"

# Configure Gemini
api_key = os.getenv("GEMINI_API_KEY")
if not api_key:
    print("Warning: GEMINI_API_KEY not found in .env file.")
else:
    genai.configure(api_key=api_key)

from fastapi.middleware.cors import CORSMiddleware

# 2. FastAPI App Setup
app = FastAPI(title="OCR & Gemini Service")

# Configure CORS to allow matching with the html file
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allows all origins
    allow_credentials=True,
    allow_methods=["*"],  # Allows all methods
    allow_headers=["*"],  # Allows all headers
)

class ChatRequest(BaseModel):
    context: str
    question: str

@app.get("/")
def home():
    return {"message": "OCR & Gemini Service is running. Use /docs to see the API."}

@app.post("/ocr")
async def ocr_endpoint(file: UploadFile = File(...)):
    """
    Accepts an image file and returns the extracted text.
    """
    try:
        # Read image file
        contents = await file.read()
        image = Image.open(io.BytesIO(contents))
        
        # Perform OCR
        text = pytesseract.image_to_string(image)
        
        return {"text": text.strip()}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/chat")
async def chat_endpoint(request: ChatRequest):
    """
    Accepts text context and a question, returns the answer from Gemini.
    """
    if not api_key:
         raise HTTPException(status_code=500, detail="Gemini API Key is not configured.")

    try:
        model = genai.GenerativeModel('gemini-flash-latest', generation_config={"response_mime_type": "application/json"})
        
        prompt = f"""
        Context:
        {request.context}

        Question: {request.question}

        Answer (return valid JSON with two fields: 'answer' and 'confidence_score' as an integer between 0 and 100 representing how confident you are based ONLY on the context provided):
        """
        
        response = model.generate_content(prompt)
        
        return {"answer": response.text}
    except Exception as e:
         raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="127.0.0.1", port=8000)
