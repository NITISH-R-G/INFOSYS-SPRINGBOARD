# Car Contract Review and Negotiation AI Assistant

An AI-powered application to help consumers review, understand, and negotiate car lease/loan contracts.

## Features

- **Contract Upload & OCR**: Upload PDF/image contracts for text extraction
- **AI-Powered SLA Extraction**: Automatically extract key terms (APR, payments, mileage, penalties)
- **Contract Fairness Score**: Get a 0-100 score evaluating contract fairness
- **Red Flag Detection**: Identify hidden fees and risky clauses
- **VIN Lookup**: Get vehicle history and recall information
- **AI Negotiation Assistant**: Get help negotiating better terms
- **Price Estimation**: Compare with fair market values

## Tech Stack

- **Backend**: Python 3.11+, FastAPI, SQLAlchemy
- **AI/LLM**: Google Gemini API
- **OCR**: Tesseract, PyMuPDF
- **Frontend**: React (Vite), CSS3
- **Database**: SQLite (dev) / PostgreSQL (prod)

## Quick Start

### Backend

```bash
cd backend
python -m venv venv
venv\Scripts\activate  # Windows
pip install -r requirements.txt
copy .env.example .env  # Add your API keys
python -m uvicorn app.main:app --reload
```

### Frontend

```bash
cd frontend
npm install
npm run dev
```

## API Documentation

Once running, visit: http://localhost:8000/docs

## Project Structure

```
CarContractApp/
├── backend/
│   ├── app/
│   │   ├── main.py           # FastAPI entry point
│   │   ├── config.py         # Configuration
│   │   ├── database.py       # DB models & connection
│   │   ├── routers/          # API endpoints
│   │   └── services/         # Business logic
│   └── requirements.txt
├── frontend/
│   └── src/
└── README.md
```

## License

MIT
