"""
OCR Service
Handles text extraction from PDFs and images using Tesseract and PyMuPDF
"""
import io
from pathlib import Path
from typing import Optional, Tuple
from PIL import Image
import pytesseract

try:
    import fitz  # PyMuPDF
    PYMUPDF_AVAILABLE = True
except ImportError:
    PYMUPDF_AVAILABLE = False

from ..config import settings


class OCRService:
    """Service for extracting text from documents"""
    
    def __init__(self):
        # Set Tesseract path
        pytesseract.pytesseract.tesseract_cmd = settings.TESSERACT_CMD
    
    def extract_text_from_image(self, image_bytes: bytes) -> str:
        """
        Extract text from an image file
        
        Args:
            image_bytes: Raw image bytes
            
        Returns:
            Extracted text string
        """
        try:
            image = Image.open(io.BytesIO(image_bytes))
            
            # Convert to RGB if necessary (for PNG with transparency)
            if image.mode in ('RGBA', 'P'):
                image = image.convert('RGB')
            
            # Perform OCR
            text = pytesseract.image_to_string(image, lang='eng')
            
            return text.strip()
        except Exception as e:
            raise OCRException(f"Failed to extract text from image: {str(e)}")
    
    def extract_text_from_pdf(self, pdf_bytes: bytes) -> str:
        """
        Extract text from a PDF file
        Uses PyMuPDF for native text, falls back to OCR for scanned PDFs
        
        Args:
            pdf_bytes: Raw PDF bytes
            
        Returns:
            Extracted text string
        """
        if not PYMUPDF_AVAILABLE:
            raise OCRException("PyMuPDF not installed. Install with: pip install PyMuPDF")
        
        try:
            # Open PDF from bytes
            doc = fitz.open(stream=pdf_bytes, filetype="pdf")
            
            all_text = []
            
            for page_num, page in enumerate(doc):
                # Try to extract native text first
                text = page.get_text()
                
                if text.strip():
                    all_text.append(f"--- Page {page_num + 1} ---\n{text}")
                else:
                    # Fallback to OCR for scanned pages
                    pix = page.get_pixmap(dpi=300)
                    img_bytes = pix.tobytes("png")
                    ocr_text = self.extract_text_from_image(img_bytes)
                    all_text.append(f"--- Page {page_num + 1} (OCR) ---\n{ocr_text}")
            
            doc.close()
            
            return "\n\n".join(all_text).strip()
        except Exception as e:
            raise OCRException(f"Failed to extract text from PDF: {str(e)}")
    
    def extract_text(self, file_bytes: bytes, filename: str) -> Tuple[str, str]:
        """
        Extract text from a file based on its extension
        
        Args:
            file_bytes: Raw file bytes
            filename: Original filename (for extension detection)
            
        Returns:
            Tuple of (extracted_text, file_type)
        """
        ext = Path(filename).suffix.lower()
        
        if ext in ['.pdf']:
            return self.extract_text_from_pdf(file_bytes), 'pdf'
        elif ext in ['.png', '.jpg', '.jpeg', '.tiff', '.bmp', '.webp']:
            return self.extract_text_from_image(file_bytes), 'image'
        else:
            raise OCRException(f"Unsupported file type: {ext}")
    
    def preprocess_image(self, image: Image.Image) -> Image.Image:
        """
        Preprocess image for better OCR accuracy
        
        Args:
            image: PIL Image object
            
        Returns:
            Preprocessed PIL Image
        """
        # Convert to grayscale
        if image.mode != 'L':
            image = image.convert('L')
        
        # Increase contrast (simple thresholding)
        # This helps with scanned documents
        threshold = 128
        image = image.point(lambda p: 255 if p > threshold else 0)
        
    def get_text_coordinates(self, pdf_bytes: bytes, text_query: str) -> list:
        """
        Find coordinates of text in a PDF
        
        Args:
            pdf_bytes: Raw PDF bytes
            text_query: Text string to search for
            
        Returns:
            List of matches with page number and coordinates
            [{'page': 1, 'rect': [x0, y0, x1, y1]}]
        """
        if not PYMUPDF_AVAILABLE:
            return []
            
        try:
            doc = fitz.open(stream=pdf_bytes, filetype="pdf")
            matches = []
            
            # Text queries often have whitespace differences
            # If query is long, take a significant substring to search
            search_term = text_query[:50] if len(text_query) > 100 else text_query
            search_term = search_term.strip()
            
            for page_num, page in enumerate(doc):
                # Search for text
                # We use quad=True to get coordinates
                quads = page.search_for(search_term, quads=True)
                
                # Convert quads to rects [x0, y0, x1, y1]
                # PyMuPDF uses points (1/72 inch)
                for quad in quads:
                    rect = quad.rect
                    matches.append({
                        "page": page_num + 1,
                        "rect": [rect.x0, rect.y0, rect.x1, rect.y1]
                    })
                    
            doc.close()
            return matches
            
        except Exception as e:
            print(f"Coordinate extraction failed: {str(e)}")
            return []


class OCRException(Exception):
    """Custom exception for OCR errors"""
    pass


# Singleton instance
ocr_service = OCRService()
