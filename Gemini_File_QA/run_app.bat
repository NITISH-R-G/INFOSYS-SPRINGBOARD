@echo off
cd /d "%~dp0"
echo Starting Gemini File Q&A Tool...
if exist venv\Scripts\activate.bat (
    call venv\Scripts\activate
    python main.py
) else (
    echo Virtual environment not found. Please ensure setup was completed.
)
pause
