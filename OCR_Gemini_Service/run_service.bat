@echo off
cd /d "%~dp0"
echo Starting OCR & Gemini Service...
echo Docs will be available at: http://127.0.0.1:8000/docs
if exist venv\Scripts\activate.bat (
    call venv\Scripts\activate
    uvicorn main:app --reload --host 127.0.0.1 --port 8000
) else (
    echo Virtual environment not found. Please ensure dependencies are installed.
)
pause
