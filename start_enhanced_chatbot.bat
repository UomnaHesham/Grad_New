@echo off
echo Starting Enhanced Medical Chatbot with Image Analysis...
echo.

REM Check if Python is installed
python --version >nul 2>&1
if errorlevel 1 (
    echo Error: Python is not installed or not in PATH
    echo Please install Python 3.8 or higher
    pause
    exit /b 1
)

REM Check if virtual environment exists
if not exist "venv" (
    echo Creating virtual environment...
    python -m venv venv
)

REM Activate virtual environment
echo Activating virtual environment...
call venv\Scripts\activate.bat

REM Install/upgrade requirements
echo Installing required packages...
pip install -r requirements.txt

REM Create uploads directory if it doesn't exist
if not exist "lib\uploads" (
    echo Creating uploads directory...
    mkdir lib\uploads
)

REM Check if RAG data exists
if not exist "RAG\train.csv" (
    echo Warning: RAG training data not found at RAG\train.csv
    echo The chatbot will use fallback medical data.
    echo.
)

echo.
echo ========================================
echo  Medical Chatbot Server Starting...
echo ========================================
echo.
echo Server will be available at:
echo - Main API: http://localhost:5000
echo - 🖼️ IMAGE UPLOAD INTERFACE: http://localhost:5000/upload
echo - Health Check: http://localhost:5000/health
echo - Chat API: http://localhost:5000/chat
echo.
echo Features enabled:
echo [✓] RAG-Enhanced Medical Responses
echo [✓] Image Analysis with Gemini Vision
echo [✓] Web-based Image Upload Interface
echo [✓] File Upload Support
echo [✓] Base64 Image Processing
echo [✓] Arabic and English Support
echo.
echo 📱 TO UPLOAD IMAGES:
echo    Open: http://localhost:5000/upload
echo.
echo Press Ctrl+C to stop the server
echo.

REM Start the server
cd lib
python chatbot_rag.py

pause
