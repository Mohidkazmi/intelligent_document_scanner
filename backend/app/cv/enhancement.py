import cv2
import numpy as np

def enhance_image(image_path: str, mode: str):
    """
    Enhances the document image based on the selected mode with HD quality preservation.
    Modes: original, grayscale, bw, magic, receipt
    """
    image = cv2.imread(image_path)
    if image is None:
        raise ValueError("Could not read image")

    if mode == "grayscale":
        gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
        # CLAHE (Contrast Limited Adaptive Histogram Equalization) for HD detail
        clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8,8))
        return clahe.apply(gray)
    
    elif mode == "bw":
        # HD Black & White: Preserve edges while removing background
        gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
        
        # 1. Denoise to prevent blocky artifacts
        denoised = cv2.GaussianBlur(gray, (3, 3), 0)
        
        # 2. Adaptive thresholding with fine-tuned parameters for sharp text
        thresh = cv2.adaptiveThreshold(
            denoised, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C, 
            cv2.THRESH_BINARY, 25, 10
        )
        
        # 3. Soften the edges slightly to restore "High-Res" look
        return cv2.medianBlur(thresh, 1)
    
    elif mode == "magic":
        # Magic Color: HDR-style enhancement
        # Sharpening
        kernel = np.array([[0, -1, 0], [-1, 5, -1], [0, -1, 0]])
        sharpened = cv2.filter2D(image, -1, kernel)
        
        # Contrast & Saturation boost
        lab = cv2.cvtColor(sharpened, cv2.COLOR_BGR2LAB)
        l, a, b = cv2.split(lab)
        clahe = cv2.createCLAHE(clipLimit=3.0, tileGridSize=(8,8))
        cl = clahe.apply(l)
        limg = cv2.merge((cl, a, b))
        return cv2.cvtColor(limg, cv2.COLOR_LAB2BGR)

    elif mode == "receipt":
        # Specialized Receipt Filter: Focus on thermal paper text recovery
        gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
        
        # Boost local contrast to catch faded text
        clahe = cv2.createCLAHE(clipLimit=4.0, tileGridSize=(12,12))
        enhanced_gray = clahe.apply(gray)
        
        # Use a more aggressive threshold for thermal text
        thresh = cv2.adaptiveThreshold(
            enhanced_gray, 255, cv2.ADAPTIVE_THRESH_MEAN_C, 
            cv2.THRESH_BINARY, 41, 15
        )
        return thresh

    return image
