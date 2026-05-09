import pytesseract
import easyocr
from PIL import Image
from app.core.config import settings
import logging

logger = logging.getLogger(__name__)

# Configure tesseract path
if settings.TESSERACT_PATH:
    pytesseract.pytesseract.tesseract_cmd = settings.TESSERACT_PATH

class OCREngine:
    def __init__(self):
        self.easyocr_reader = None

    def _get_easyocr_reader(self, langs=["en"]):
        if self.easyocr_reader is None:
            logger.info(f"Initializing EasyOCR with languages: {langs}")
            self.easyocr_reader = easyocr.Reader(langs)
        return self.easyocr_reader

    def extract_text(self, image_path: str, lang: str = "eng", engine: str = "tesseract"):
        """
        Extract text from an image using the specified engine.
        engine: 'tesseract' or 'easyocr'
        lang: Tesseract lang codes (eng, urd, ara, hin) or EasyOCR codes (en, ur, ar, hi)
        """
        try:
            if engine == "tesseract":
                return pytesseract.image_to_string(Image.open(image_path), lang=lang)
            
            elif engine == "easyocr":
                # Map tesseract codes to easyocr codes if necessary
                lang_map = {"eng": "en", "urd": "ur", "ara": "ar", "hin": "hi"}
                eo_lang = lang_map.get(lang, "en")
                reader = self._get_easyocr_reader([eo_lang])
                result = reader.readtext(image_path)
                return " ".join([res[1] for res in result])
            
            else:
                raise ValueError(f"Unsupported OCR engine: {engine}")
        except Exception as e:
            logger.error(f"OCR Extraction failed: {e}")
            raise e

ocr_engine = OCREngine()
