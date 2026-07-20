from __future__ import annotations

import io
import json
import os
import shutil
import subprocess

from fastapi import HTTPException

from src.backend.core.config import settings
from src.backend.services.report_interpreter.constants import (
    TESSERACT_CONFIG,
)


SUPPORTED_IMAGE_EXTENSIONS = {".jpg", ".jpeg", ".png", ".bmp", ".tif", ".tiff"}


def classify_upload(file_name: str, mime_type: str) -> str:
    extension = os.path.splitext(file_name)[1].lower()
    if mime_type == "application/json" or extension == ".json":
        return "json"
    if mime_type.startswith("text/") or extension == ".txt":
        return "text"
    if mime_type == "application/pdf" or extension == ".pdf":
        return "pdf"
    if mime_type.startswith("image/") or extension in SUPPORTED_IMAGE_EXTENSIONS:
        return "image"
    raise HTTPException(
        status_code=415,
        detail="Only .json, .txt, .pdf, or image files are supported.",
    )


def is_tesseract_available() -> bool:
    if not shutil.which("tesseract"):
        return False
    try:
        subprocess.run(
            ["tesseract", "--version"],
            check=True,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            timeout=2,
        )
    except Exception:
        return False
    return True


def is_poppler_available() -> bool:
    return bool(shutil.which("pdfinfo") or shutil.which("pdftoppm"))


def ocr_status() -> dict[str, bool]:
    return {
        "tesseract": is_tesseract_available(),
        "poppler": is_poppler_available(),
    }


def extract_upload_text(content: bytes, file_name: str, mime_type: str) -> str:
    upload_type = classify_upload(file_name, mime_type)
    if upload_type in {"json", "text"}:
        raw_text = content.decode("utf-8", errors="ignore")
        if upload_type == "json":
            try:
                return json.dumps(json.loads(raw_text), indent=2)
            except json.JSONDecodeError:
                return raw_text
        return raw_text

    if upload_type == "pdf":
        text = extract_text_from_pdf(content)
        if len(text) >= settings.report_interpreter_min_pdf_text_chars:
            return text
        return extract_text_from_images(content, is_pdf=True)

    return extract_text_from_images(content, is_pdf=False)


def extract_text_from_pdf(content: bytes) -> str:
    try:
        from pypdf import PdfReader
    except ImportError as exc:
        raise HTTPException(
            status_code=500,
            detail="PDF parsing requires the pypdf Python package.",
        ) from exc

    reader = PdfReader(io.BytesIO(content))
    extracted = [page.extract_text() or "" for page in reader.pages]
    return "\n".join(extracted).strip()


def extract_text_from_images(content: bytes, *, is_pdf: bool) -> str:
    status = ocr_status()
    if not status["tesseract"]:
        raise HTTPException(
            status_code=500,
            detail=(
                "Could not extract text from image/scanned report. "
                "Tesseract OCR is required for scanned PDFs and image reports."
            ),
        )

    if is_pdf:
        if not status["poppler"]:
            raise HTTPException(
                status_code=500,
                detail=(
                    "Could not extract text from scanned PDF. "
                    "Poppler is required for scanned PDF conversion."
                ),
            )
        try:
            from pdf2image import convert_from_bytes
        except ImportError as exc:
            raise HTTPException(
                status_code=500,
                detail="Scanned PDF OCR requires the pdf2image Python package.",
            ) from exc

        try:
            images = convert_from_bytes(content)
        except Exception as exc:
            raise HTTPException(
                status_code=500,
                detail=f"PDF image extraction failed: {exc}",
            ) from exc
        return "\n".join(ocr_image(image) for image in images).strip()

    try:
        from PIL import Image
    except ImportError as exc:
        raise HTTPException(
            status_code=500,
            detail="Image OCR requires the pillow Python package.",
        ) from exc

    image = Image.open(io.BytesIO(content))
    return ocr_image(image)


def ocr_image(image) -> str:
    try:
        import pytesseract
    except ImportError as exc:
        raise HTTPException(
            status_code=500,
            detail="Image OCR requires the pytesseract Python package.",
        ) from exc
    return pytesseract.image_to_string(image, config=TESSERACT_CONFIG).strip()
