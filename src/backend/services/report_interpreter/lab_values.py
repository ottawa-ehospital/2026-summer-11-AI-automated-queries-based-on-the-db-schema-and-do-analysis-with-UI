from __future__ import annotations

import re
from datetime import date
from typing import Any


def _number(raw: str | None) -> float | None:
    if raw is None:
        return None
    cleaned = re.sub(r"[<>\s]", "", raw)
    try:
        return float(cleaned)
    except ValueError:
        return None


def parse_lab_value_visuals(text: str, limit: int = 12) -> list[dict[str, Any]]:
    visuals: list[dict[str, Any]] = []
    seen = set()
    patterns = [
        re.compile(
            r"^\s*(?:[-*]\s*)?"
            r"(?P<name>[A-Za-z][A-Za-z0-9 /().,%+-]{1,70}?)\s*:\s*"
            r"(?:(?:normal|high|low|elevated|decreased|within range|outside range)\s+(?:at\s+)?)?"
            r"(?P<value>[<>]?\s*-?\d+(?:\.\d+)?)\s*"
            r"(?P<unit>[^\n(,;]{0,40})\s*"
            r"\((?:(?:normal|reference|range|normal range)[:\s]*)?"
            r"(?P<min>[<>]?\s*-?\d+(?:\.\d+)?)\s*(?:-|–|—|to)\s*"
            r"(?P<max>[<>]?\s*-?\d+(?:\.\d+)?)",
            re.IGNORECASE,
        ),
        re.compile(
            r"^\s*(?:[-*]\s*)?"
            r"(?P<name>[A-Z][A-Za-z0-9 /().-]{1,70}?)\s+"
            r"(?:is|level is|levels? are|=)\s*"
            r"(?P<value>-?\d+(?:\.\d+)?)(?P<unit>[A-Za-z/%]+)?"
            r".{0,120}?"
            r"(?:normal|reference)\s+range\s+(?:of\s+)?"
            r"(?P<min>-?\d+(?:\.\d+)?)\s*(?:-|–|—|to)\s*"
            r"(?P<max>-?\d+(?:\.\d+)?)",
            re.IGNORECASE,
        ),
        re.compile(
            r"^\s*(?:[-*]\s*)?"
            r"(?P<name>[A-Za-z][A-Za-z0-9 /().,%+-]{1,70}?)\s*:\s*"
            r"(?P<value>[<>]?\s*-?\d+(?:\.\d+)?)\s*"
            r"(?P<unit>[A-Za-z0-9^*/%µμ._-]{0,24})?"
            r".{0,140}?"
            r"(?:normal|reference)\s+range\s+(?:of\s+)?"
            r"(?P<min>[<>]?\s*-?\d+(?:\.\d+)?)\s*(?:-|–|—|to)\s*"
            r"(?P<max>[<>]?\s*-?\d+(?:\.\d+)?)",
            re.IGNORECASE,
        ),
    ]

    for pattern in patterns:
        for line in text.splitlines():
            match = pattern.search(line.strip())
            if not match:
                continue
            item = _visual_from_match(match)
            if item is None:
                continue
            key = item["name"].lower()
            if key in seen:
                continue
            seen.add(key)
            visuals.append(item)
            if len(visuals) >= limit:
                return visuals

    if len(visuals) < limit:
        score = _parse_vision_score(text)
        if score and "vision score" not in seen:
            visuals.append(score)

    if len(visuals) < limit and re.search(
        r"\b(needs follow[- ]?up|follow[- ]?up needed|requires follow[- ]?up)\b",
        text,
        re.IGNORECASE,
    ):
        visuals.append(
            {
                "name": "Retinal Follow-Up",
                "value": 1,
                "normalMin": 0,
                "normalMax": 1,
                "unit": "status",
                "status": "high",
                "display": "Needs follow-up",
            }
        )
    return visuals[:limit]


def _visual_from_match(match) -> dict[str, Any] | None:
    name = re.sub(r"\s+", " ", match.group("name")).strip(" :-")
    if not name or name.lower() in {"date", "patient", "result"}:
        return None
    value = _number(match.group("value"))
    normal_min = _number(match.group("min"))
    normal_max = _number(match.group("max"))
    if value is None or normal_min is None or normal_max is None:
        return None
    if normal_min > normal_max:
        normal_min, normal_max = normal_max, normal_min
    if normal_min == normal_max:
        return None
    status = "normal"
    if value < normal_min:
        status = "low"
    elif value > normal_max:
        status = "high"
    unit = re.sub(
        r"\b(?:within|outside|above|below)\s+(?:the\s+)?(?:normal\s+)?range\b|"
        r"\b(?:normal|high|low|elevated|decreased)\b",
        "",
        re.sub(r"\s+", " ", match.groupdict().get("unit") or ""),
        flags=re.IGNORECASE,
    ).strip(" ,;")
    return {
        "name": name,
        "value": value,
        "normalMin": normal_min,
        "normalMax": normal_max,
        "unit": unit,
        "status": status,
    }


def _parse_vision_score(text: str) -> dict[str, Any] | None:
    patterns = [
        re.compile(
            r"\b(?:vision|vision score|score)\b[^\n:]*:\s*"
            r"(?:[A-Za-z0-9 /().+-]{0,50}?)"
            r"\(\s*score\s*:\s*(?P<num>\d+(?:\.\d+)?)\s*/\s*(?P<den>\d+(?:\.\d+)?)\s*\)",
            re.IGNORECASE,
        ),
        re.compile(
            r"\b(?:vision score|vision|score)\b\s*:\s*"
            r"(?P<num>\d+(?:\.\d+)?)\s*/\s*(?P<den>\d+(?:\.\d+)?)",
            re.IGNORECASE,
        ),
    ]
    for line in text.splitlines():
        for pattern in patterns:
            match = pattern.search(line.strip())
            if not match:
                continue
            value = _number(match.group("num"))
            normal_max = _number(match.group("den"))
            if value is None or normal_max is None or normal_max <= 0:
                continue
            return {
                "name": "Vision Score",
                "value": value,
                "normalMin": 0,
                "normalMax": normal_max,
                "unit": "score",
                "status": "normal" if value <= normal_max else "high",
            }
    return None


def merge_lab_value_visuals(*groups: list[dict[str, Any]], limit: int = 12) -> list[dict[str, Any]]:
    merged: list[dict[str, Any]] = []
    seen = set()
    for group in groups:
        for value in group:
            key = str(value.get("name", "")).lower().strip()
            if not key or key in seen:
                continue
            seen.add(key)
            merged.append(value)
            if len(merged) >= limit:
                return merged
    return merged


def extract_report_date(text: str) -> str:
    date_patterns = [
        r"\b(?:test|report|collection|collected|specimen|exam)\s+date\s*[:\-]\s*(?P<date>\d{4}[-/]\d{1,2}[-/]\d{1,2})",
        r"\b(?:test|report|collection|collected|specimen|exam)\s+date\s*[:\-]\s*(?P<date>\d{1,2}[-/]\d{1,2}[-/]\d{2,4})",
        r"\b(?P<date>\d{4}[-/]\d{1,2}[-/]\d{1,2})\b",
    ]
    for pattern in date_patterns:
        for match in re.finditer(pattern, text, re.IGNORECASE):
            line_start = text.rfind("\n", 0, match.start()) + 1
            label_context = text[line_start:match.start()].lower()
            if re.search(r"(date\s+of\s+birth|birth\s+date|dob)", label_context):
                continue
            parsed = _parse_date(match.group("date"))
            if parsed:
                return parsed
    return date.today().isoformat()


def _parse_date(raw: str) -> str | None:
    parts = raw.replace("/", "-").split("-")
    if len(parts) != 3:
        return None
    try:
        if len(parts[0]) == 4:
            year, month, day = int(parts[0]), int(parts[1]), int(parts[2])
        else:
            month, day, year = int(parts[0]), int(parts[1]), int(parts[2])
            if year < 100:
                year += 2000
        return date(year, month, day).isoformat()
    except ValueError:
        return None


def detect_report_type(text: str, file_name: str, lab_values: list[dict[str, Any]]) -> str:
    haystack = f"{file_name}\n{text}".lower()
    if re.search(r"\b(retina|retinal|vision|eye exam|ophthalm|visual acuity)\b", haystack):
        return "eye"
    if re.search(r"\b(tumou?r|mass|lesion|oncology|biopsy)\b", haystack):
        return "tumor"
    if re.search(r"\b(diagnosis|diagnosed|icd|diagnosis code)\b", haystack):
        return "diagnosis"
    blood_markers = {
        "rbc", "red blood", "wbc", "white blood", "hemoglobin", "haemoglobin",
        "hematocrit", "haematocrit", "platelet", "glucose", "cholesterol",
        "triglyceride", "alt", "ast", "bilirubin", "creatinine", "mcv", "mch",
        "lymphocyte", "neutrophil", "monocyte", "eosinophil", "basophil",
    }
    lab_names = " ".join(str(value.get("name", "")).lower() for value in lab_values)
    if any(marker in haystack or marker in lab_names for marker in blood_markers):
        return "blood"
    if re.search(r"\b(lab|urine|sample|culture|x-?ray|mri|ct scan|pathology)\b", haystack):
        return "lab"
    return "blood" if lab_values else "lab"
