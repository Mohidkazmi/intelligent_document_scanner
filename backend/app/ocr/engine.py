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
        Returns a dictionary with 'text' and 'data' (bounding boxes).
        """
        try:
            if engine == "tesseract":
                # Get detailed data including bounding boxes
                df = pytesseract.image_to_data(Image.open(image_path), lang=lang, output_type=pytesseract.Output.DICT)
                
                full_text = pytesseract.image_to_string(Image.open(image_path), lang=lang)
                
                # Filter out empty text blocks
                blocks = []
                for i in range(len(df['text'])):
                    if int(df['conf'][i]) > 0: # Only blocks with confidence > 0
                        blocks.append({
                            "text": df['text'][i],
                            "left": df['left'][i],
                            "top": df['top'][i],
                            "width": df['width'][i],
                            "height": df['height'][i],
                            "conf": df['conf'][i]
                        })
                
                return {
                    "text": full_text,
                    "blocks": blocks
                }
            
            elif engine == "easyocr":
                lang_map = {"eng": "en", "urd": "ur", "ara": "ar", "hin": "hi"}
                eo_lang = lang_map.get(lang, "en")
                reader = self._get_easyocr_reader([eo_lang])
                
                result = reader.readtext(image_path)
                
                blocks = []
                full_text_parts = []
                for (bbox, text, prob) in result:
                    # EasyOCR returns bbox as [[x1,y1], [x2,y2], [x3,y3], [x4,y4]]
                    (tl, tr, br, bl) = bbox
                    blocks.append({
                        "text": text,
                        "left": int(tl[0]),
                        "top": int(tl[1]),
                        "width": int(tr[0] - tl[0]),
                        "height": int(bl[1] - tl[1]),
                        "conf": float(prob * 100)
                    })
                    full_text_parts.append(text)
                
                return {
                    "text": " ".join(full_text_parts),
                    "blocks": blocks
                }
            
            else:
                raise ValueError(f"Unsupported OCR engine: {engine}")
        except Exception as e:
            logger.error(f"OCR Extraction failed: {e}")
            raise e

ocr_engine = OCREngine()
