from __future__ import annotations

from typing import Any

from pydantic import BaseModel, ConfigDict, Field


class ReportInterpreterModel(BaseModel):
    model_config = ConfigDict(populate_by_name=True)


class ReportChatMessage(ReportInterpreterModel):
    role: str
    content: str


class ReportChatRequest(ReportInterpreterModel):
    messages: list[ReportChatMessage]
    file_context: str | None = Field(default=None, alias="fileContext")


class SuggestedQuestionsRequest(ReportInterpreterModel):
    latest_response: str = Field(alias="latestResponse")
    file_context: str | None = Field(default=None, alias="fileContext")
    patient_id: int | None = Field(default=None, alias="patientId")


class PatientCreateRequest(ReportInterpreterModel):
    name: str
    gender: str | None = None
    email: str | None = None
    phone: str | None = None
    age: int | None = None


class PatientOption(ReportInterpreterModel):
    patient_id: int | str | None = None
    name: str


class LabValueVisual(ReportInterpreterModel):
    name: str
    value: float
    normal_min: float = Field(alias="normalMin")
    normal_max: float = Field(alias="normalMax")
    status: str
    unit: str = ""
    display: str | None = None


class AssignPatientRequest(ReportInterpreterModel):
    name: str
    lab_values: list[LabValueVisual] = Field(default_factory=list, alias="labValues")
    report_date: str | None = Field(default=None, alias="reportDate")
    detected_test_type: str | None = Field(default=None, alias="detectedTestType")


class AssignPatientResponse(ReportInterpreterModel):
    patient: dict[str, Any] | None = None
    saved_lab_record_count: int = Field(alias="savedLabRecordCount")
    save_errors: list[str] = Field(default_factory=list, alias="saveErrors")


class AnalyzeReportResponse(ReportInterpreterModel):
    analysis: str
    file_context: str = Field(alias="fileContext")
    lab_values: list[dict[str, Any]] = Field(default_factory=list, alias="labValues")
    patient: dict[str, Any] | None = None
    saved_lab_record_count: int = Field(alias="savedLabRecordCount")
    save_errors: list[str] = Field(default_factory=list, alias="saveErrors")
    detected_test_type: str = Field(alias="detectedTestType")
    patient_name_needed: bool = Field(alias="patientNameNeeded")
    patient_name_question: str = Field(alias="patientNameQuestion")
    report_date: str | None = Field(default=None, alias="reportDate")


class TestType(ReportInterpreterModel):
    id: str
    name: str
    table: str
    date_field: str = Field(alias="dateField")


class SavedRecordResponse(ReportInterpreterModel):
    formatted_text: str = Field(alias="formattedText")
    test_type: str = Field(alias="testType")


class ReportChatResponse(ReportInterpreterModel):
    reply: str


class SuggestedQuestionsResponse(ReportInterpreterModel):
    questions: list[str]
