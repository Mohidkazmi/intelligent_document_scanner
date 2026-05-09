import cv2
import numpy as np

def enhance_image(image_path: str, mode: str):
    """
    Enhances the document image based on the selected mode.
    The 'bw' mode is optimized to match the high-contrast, clean look of CamScanner.
    """
    image = cv2.imread(image_path)
    if image is None:
        raise ValueError("Could not read image")

    if mode == "grayscale":
        gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
        # HD Grayscale with shadow removal
        clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8,8))
        return clahe.apply(gray)
    
    elif mode == "bw":
        # --- CamScanner-Style B&W Implementation ---
        gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
        
        # 1. Edge-preserving Denoising (The Bilateral Secret)
        # This removes paper texture while keeping text crisp
        denoised = cv2.bilateralFilter(gray, 9, 75, 75)
        
        # 2. Local contrast normalization to push background to white
        clahe = cv2.createCLAHE(clipLimit=3.0, tileGridSize=(8,8))
        high_contrast = clahe.apply(denoised)
        
        # 3. Large-block Adaptive Thresholding
        # Using a large block size (41) ensures bold text stays solid
        thresh = cv2.adaptiveThreshold(
            high_contrast, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C, 
            cv2.THRESH_BINARY, 41, 15
        )
        
        # 4. Final Polish: Small median blur to remove "salt and pepper" noise
        return cv2.medianBlur(thresh, 1)
    
    elif mode == "magic":
        # Magic Color: High-end HDR style
        kernel = np.array([[0, -1, 0], [-1, 5, -1], [0, -1, 0]])
        sharpened = cv2.filter2D(image, -1, kernel)
        lab = cv2.cvtColor(sharpened, cv2.COLOR_BGR2LAB)
        l, a, b = cv2.split(lab)
        clahe = cv2.createCLAHE(clipLimit=3.0, tileGridSize=(8,8))
        cl = clahe.apply(l)
        return cv2.cvtColor(cv2.merge((cl, a, b)), cv2.COLOR_LAB2BGR)

    elif mode == "receipt":
        # Receipt: Optimized for thermal/faint text
        gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
        # Use very aggressive CLAHE for faint text
        clahe = cv2.createCLAHE(clipLimit=5.0, tileGridSize=(12,12))
        enhanced = clahe.apply(gray)
        return cv2.adaptiveThreshold(
            enhanced, 255, cv2.ADAPTIVE_THRESH_MEAN_C, 
            cv2.THRESH_BINARY, 51, 10
        )

    return image
