from __future__ import annotations


MAX_CONTEXT_CHARS = 12000
MIN_PDF_TEXT_CHARS = 200
TESSERACT_CONFIG = "--oem 1 --psm 6"

DATABASE_RECORD_TYPES = [
    {"id": "blood", "name": "Blood Tests", "table": "bloodtests", "dateField": "test_date"},
    {"id": "eye", "name": "Eye Tests", "table": "eye_test", "dateField": "test_date"},
    {"id": "lab", "name": "Lab Tests", "table": "lab_tests", "dateField": "test_date"},
    {"id": "diagnosis", "name": "Diagnoses", "table": "diagnosis", "dateField": "diagnosis_date"},
    {"id": "tumor", "name": "Tumor Records", "table": "tumor", "dateField": "diagnosed_on"},
]

TEST_TYPE_BY_ID = {item["id"]: item for item in DATABASE_RECORD_TYPES}
