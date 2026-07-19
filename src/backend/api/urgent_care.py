from __future__ import annotations

from fastapi import APIRouter

from src.backend.schemas.urgent_care import (
    UrgentCareActionResponse,
    UrgentCareAlertsResponse,
    UrgentCareCheckInResponse,
    UrgentCareFeedbackRequest,
    UrgentCareFeedbackResponse,
    UrgentCareHealthResponse,
    UrgentCareHistoryResponse,
    UrgentCareIntakeRequest,
    UrgentCarePatientsResponse,
    UrgentCareQueuesResponse,
    UrgentCareWorkflowFeedbackRequest,
)
from src.backend.services.urgent_care import service


router = APIRouter(prefix="/urgent-care", tags=["urgent-care"])


@router.get("/health", response_model=UrgentCareHealthResponse)
async def health() -> dict:
    return await service.health_response()


@router.get("/customer/health", response_model=UrgentCareHealthResponse)
async def customer_health() -> dict:
    return await service.health_response()


@router.post("/customer/check-in", response_model=UrgentCareCheckInResponse)
async def customer_check_in(request: UrgentCareIntakeRequest) -> dict:
    return await service.customer_check_in(request)


@router.get("/customer/visits/{visit_id}/status")
async def customer_visit_status(visit_id: int) -> dict:
    return await service.status_for_visit(visit_id)


@router.post("/customer/visits/{visit_id}/feedback", response_model=UrgentCareFeedbackResponse)
async def customer_visit_feedback(
    visit_id: int,
    request: UrgentCareFeedbackRequest,
) -> dict:
    return await service.customer_feedback(visit_id, request)


@router.get("/customer/patients/{patient_id}/history", response_model=UrgentCareHistoryResponse)
async def customer_patient_history(patient_id: int) -> dict:
    return await service.history_for_patient(patient_id)


@router.get("/workflow/health", response_model=UrgentCareHealthResponse)
async def workflow_health() -> dict:
    return await service.health_response()


@router.post("/workflow/intake")
async def workflow_intake(request: UrgentCareIntakeRequest) -> dict:
    return await service.intake(request)


@router.get("/workflow/queues", response_model=UrgentCareQueuesResponse)
async def workflow_queues() -> dict:
    return await service.queues_response()


@router.get("/workflow/patients", response_model=UrgentCarePatientsResponse)
async def workflow_patients() -> dict:
    return await service.patients_response()


@router.get("/workflow/feedback")
async def workflow_feedback() -> dict:
    return await service.feedback_rows()


@router.post("/workflow/feedback", response_model=UrgentCareFeedbackResponse)
async def workflow_save_feedback(request: UrgentCareWorkflowFeedbackRequest) -> dict:
    return await service.save_feedback(request)


@router.get("/workflow/alerts", response_model=UrgentCareAlertsResponse)
async def workflow_alerts() -> dict:
    return await service.alerts_response()


@router.post("/workflow/visits/{visit_id}/notify", response_model=UrgentCareActionResponse)
async def workflow_notify_visit(visit_id: int) -> dict:
    return await service.notify_visit(visit_id)


@router.post("/workflow/visits/{visit_id}/start", response_model=UrgentCareActionResponse)
async def workflow_start_visit(visit_id: int) -> dict:
    return await service.start_visit(visit_id)


@router.post("/workflow/visits/{visit_id}/complete", response_model=UrgentCareActionResponse)
async def workflow_complete_visit(visit_id: int) -> dict:
    return await service.complete_visit(visit_id)
