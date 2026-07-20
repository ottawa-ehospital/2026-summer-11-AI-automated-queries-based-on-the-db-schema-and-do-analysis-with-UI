from __future__ import annotations

from datetime import date
from typing import Any

from fastapi import APIRouter, File, Form, UploadFile

from src.backend.schemas.report_interpreter import (
    AnalyzeReportResponse,
    AssignPatientRequest,
    AssignPatientResponse,
    PatientCreateRequest,
    ReportChatRequest,
    ReportChatResponse,
    SavedRecordResponse,
    SuggestedQuestionsRequest,
    SuggestedQuestionsResponse,
    TestType,
)
from src.backend.services.report_interpreter.analysis import (
    analyze_report,
    chat_with_report_context,
)
from src.backend.services.report_interpreter.extraction import ocr_status
from src.backend.services.report_interpreter.patients import (
    create_patient_from_request,
    find_or_create_patient_by_name,
    list_patients,
    save_lab_values_for_patient,
)
from src.backend.services.report_interpreter.saved_records import (
    get_test_dates,
    get_test_types,
    get_tests_by_type_and_date,
)
from src.backend.services.report_interpreter.suggestions import suggest_questions


router = APIRouter(prefix="/report-interpreter", tags=["report-interpreter"])


@router.get("/health")
async def health() -> dict[str, Any]:
    return {"status": "ok", "ocr": ocr_status()}


@router.post("/patients")
async def create_patient(request: PatientCreateRequest) -> dict[str, Any]:
    patient = await create_patient_from_request(
        name=request.name,
        gender=request.gender,
        email=request.email,
        phone=request.phone,
        age=request.age,
    )
    return {"patient": patient}


@router.get("/patients")
async def get_patients() -> list[dict[str, Any]]:
    return await list_patients()


@router.post("/reports/assign-patient", response_model=AssignPatientResponse)
async def assign_report_patient(request: AssignPatientRequest) -> dict[str, Any]:
    patient = await find_or_create_patient_by_name(request.name)
    patient_id = _patient_id(patient)
    save_result = await save_lab_values_for_patient(
        patient_id,
        [value.model_dump(by_alias=True) for value in request.lab_values],
        request.report_date or date.today().isoformat(),
        request.detected_test_type or "blood",
    )
    return {
        "patient": patient,
        "savedLabRecordCount": save_result["count"],
        "saveErrors": save_result["errors"],
    }


@router.post("/chat", response_model=ReportChatResponse)
async def chat(request: ReportChatRequest) -> dict[str, str]:
    reply = chat_with_report_context(
        [message.model_dump() for message in request.messages],
        request.file_context,
    )
    return {"reply": reply}


@router.post("/suggest-questions", response_model=SuggestedQuestionsResponse)
async def report_suggest_questions(request: SuggestedQuestionsRequest) -> dict[str, list[str]]:
    questions = await suggest_questions(
        request.latest_response,
        request.file_context,
        request.patient_id,
    )
    return {"questions": questions}


@router.post("/analyze-file", response_model=AnalyzeReportResponse)
async def analyze_file(
    file: UploadFile = File(...),
    previousFileContext: str | None = Form(None),
    userQuestion: str | None = Form(None),
    patientId: int | None = Form(None),
    fromSavedRecord: bool = Form(False),
) -> dict[str, Any]:
    content = await file.read()
    return await analyze_report(
        content=content,
        file_name=file.filename or "uploaded-file",
        mime_type=file.content_type or "",
        previous_file_context=previousFileContext,
        user_question=userQuestion,
        patient_id=patientId,
        from_saved_record=fromSavedRecord,
    )


@router.get("/test-types", response_model=list[TestType])
async def test_types() -> list[dict[str, str]]:
    return get_test_types()


@router.get("/tests/{test_type}/dates")
async def test_dates(test_type: str, patientId: int) -> list[str]:
    return await get_test_dates(test_type, patientId)


@router.get("/tests/{test_type}/{test_date}", response_model=SavedRecordResponse)
async def saved_record(
    test_type: str,
    test_date: str,
    patientId: int,
) -> dict[str, Any]:
    return await get_tests_by_type_and_date(test_type, test_date, patientId)


def _patient_id(patient: dict[str, Any] | None) -> int | None:
    if not patient:
        return None
    try:
        return int(patient.get("patient_id"))
    except (TypeError, ValueError):
        return None
