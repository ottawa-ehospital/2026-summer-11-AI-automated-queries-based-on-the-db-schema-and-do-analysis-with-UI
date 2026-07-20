#!/usr/bin/env python3
"""Seed fixed demo patients and recent health data for LLM alert testing.

The script is intentionally idempotent:
- fixed demo emails are used as the source of truth for users
- user ids are reused as patient ids for app login and backend queries
- recent scenario data is inserted only when the patient has no data in the
  last analysis window
"""

from __future__ import annotations

import argparse
import json
import os
import sys
from dataclasses import dataclass
from datetime import UTC, datetime, timedelta
from typing import Any

import httpx


DEFAULT_BASE_URL = "https://aetab8pjmb.us-east-1.awsapprunner.com"
DEFAULT_AUTH_BASE_URL = "https://tysnx3mi2s.us-east-1.awsapprunner.com"
DEFAULT_WINDOW_HOURS = 3
DEMO_MARKER = "llm_demo_health_scenario"
DEMO_PASSWORD = "123456"


@dataclass(frozen=True)
class DemoScenario:
    key: str
    fallback_patient_id: int
    email: str
    username: str
    name: str
    gender: str
    dob: str
    age: int
    blood_group: str
    phone_number: str
    document_prefix: str
    wearable_rows: tuple[dict[str, Any], ...]
    vitals_rows: tuple[dict[str, Any], ...]
    diagnosis_rows: tuple[dict[str, Any], ...] = ()
    medical_history_rows: tuple[dict[str, Any], ...] = ()
    prescription_form_rows: tuple[dict[str, Any], ...] = ()


DEMO_SCENARIOS = (
    DemoScenario(
        key="normal",
        fallback_patient_id=9201,
        email="normal@demo.com",
        username="normal_demo",
        name="LLM Demo Normal",
        gender="Female",
        dob="1988-04-12",
        age=38,
        blood_group="O+",
        phone_number="5550100",
        document_prefix="DEMO-NORMAL-9201",
        wearable_rows=(
            {"minutes_ago": 175, "heart_rate": 66, "steps": 180, "calories": 18, "sleep": 7.6},
            {"minutes_ago": 160, "heart_rate": 67, "steps": 360, "calories": 30, "sleep": 7.6},
            {"minutes_ago": 145, "heart_rate": 68, "steps": 540, "calories": 43, "sleep": 7.6},
            {"minutes_ago": 130, "heart_rate": 69, "steps": 760, "calories": 58, "sleep": 7.5},
            {"minutes_ago": 115, "heart_rate": 70, "steps": 980, "calories": 73, "sleep": 7.5},
            {"minutes_ago": 100, "heart_rate": 72, "steps": 1240, "calories": 91, "sleep": 7.5},
            {"minutes_ago": 85, "heart_rate": 71, "steps": 1480, "calories": 108, "sleep": 7.5},
            {"minutes_ago": 70, "heart_rate": 73, "steps": 1720, "calories": 124, "sleep": 7.4},
            {"minutes_ago": 55, "heart_rate": 72, "steps": 1940, "calories": 140, "sleep": 7.4},
            {"minutes_ago": 40, "heart_rate": 70, "steps": 2160, "calories": 156, "sleep": 7.4},
            {"minutes_ago": 25, "heart_rate": 69, "steps": 2360, "calories": 171, "sleep": 7.4},
            {"minutes_ago": 10, "heart_rate": 68, "steps": 2520, "calories": 184, "sleep": 7.4},
        ),
        vitals_rows=(
            {"minutes_ago": 170, "blood_pressure": "114/72", "heart_rate": 66},
            {"minutes_ago": 140, "blood_pressure": "116/73", "heart_rate": 68},
            {"minutes_ago": 110, "blood_pressure": "117/74", "heart_rate": 70},
            {"minutes_ago": 80, "blood_pressure": "118/75", "heart_rate": 72},
            {"minutes_ago": 50, "blood_pressure": "117/74", "heart_rate": 71},
            {"minutes_ago": 25, "blood_pressure": "116/73", "heart_rate": 69},
            {"minutes_ago": 10, "blood_pressure": "115/72", "heart_rate": 68},
        ),
    ),
    DemoScenario(
        key="hypertension_med_symptom",
        fallback_patient_id=9202,
        email="hypertension@demo.com",
        username="hypertension_demo",
        name="LLM Demo Hypertension",
        gender="Male",
        dob="1974-09-03",
        age=51,
        blood_group="A+",
        phone_number="5550101",
        document_prefix="DEMO-HYP-9202",
        wearable_rows=(
            {"minutes_ago": 175, "heart_rate": 92, "steps": 40, "calories": 8, "sleep": 5.1},
            {"minutes_ago": 160, "heart_rate": 94, "steps": 70, "calories": 12, "sleep": 5.1},
            {"minutes_ago": 145, "heart_rate": 96, "steps": 95, "calories": 16, "sleep": 5.1},
            {"minutes_ago": 130, "heart_rate": 99, "steps": 130, "calories": 21, "sleep": 5.0},
            {"minutes_ago": 115, "heart_rate": 102, "steps": 170, "calories": 27, "sleep": 5.0},
            {"minutes_ago": 100, "heart_rate": 101, "steps": 220, "calories": 34, "sleep": 5.0},
            {"minutes_ago": 85, "heart_rate": 103, "steps": 260, "calories": 40, "sleep": 5.0},
            {"minutes_ago": 70, "heart_rate": 105, "steps": 310, "calories": 47, "sleep": 4.9},
            {"minutes_ago": 55, "heart_rate": 104, "steps": 360, "calories": 53, "sleep": 4.9},
            {"minutes_ago": 40, "heart_rate": 101, "steps": 420, "calories": 60, "sleep": 4.9},
            {"minutes_ago": 25, "heart_rate": 99, "steps": 480, "calories": 68, "sleep": 4.9},
            {"minutes_ago": 10, "heart_rate": 98, "steps": 540, "calories": 75, "sleep": 4.9},
        ),
        vitals_rows=(
            {"minutes_ago": 170, "blood_pressure": "154/94", "heart_rate": 92},
            {"minutes_ago": 140, "blood_pressure": "158/96", "heart_rate": 96},
            {"minutes_ago": 110, "blood_pressure": "163/100", "heart_rate": 101},
            {"minutes_ago": 80, "blood_pressure": "166/102", "heart_rate": 103},
            {
                "minutes_ago": 50,
                "blood_pressure": "165/101",
                "heart_rate": 102,
                "symptom_note": "Symptom: headache severity 5/10 after mild exertion.",
            },
            {
                "minutes_ago": 25,
                "blood_pressure": "162/100",
                "heart_rate": 98,
                "symptom_note": "Symptom: headache severity 6/10 with mild dizziness in the last hour.",
            },
            {"minutes_ago": 10, "blood_pressure": "160/98", "heart_rate": 97},
        ),
        diagnosis_rows=(
            {
                "doctor_id": 1,
                "diagnosis_code": "I10",
                "diagnosis_description": "Essential hypertension",
                "diagnosis_date": "2026-01-15",
            },
        ),
        medical_history_rows=(
            {
                "diagnosed_by": "Demo Clinician",
                "condition": "Hypertension",
                "status": "active",
                "severity": "moderate",
                "diagnosis_date": "2026-01-15",
                "notes": "Demo history for blood-pressure alert analysis.",
                "treatment_given": "Antihypertensive medication prescribed",
                "followup_required": 1,
            },
        ),
        prescription_form_rows=(
            {
                "prescriber_id": 1,
                "medication_name": "Amlodipine",
                "medication_strength": "5 mg",
                "medication_form": "tablet",
                "dosage_instructions": "Take one tablet by mouth every morning.",
                "quantity": 30,
                "refills_allowed": 2,
                "date_prescribed": "2026-01-15",
                "expiry_date": "2026-12-31",
                "status": "active",
                "notes": "Morning medication reminder context for LLM demo.",
                "pharmacy_id": 1,
            },
        ),
    ),
)


class EHospitalAuthSeedClient:
    def __init__(self, base_url: str, dry_run: bool = False) -> None:
        self.base_url = base_url.rstrip("/")
        self.dry_run = dry_run
        self._client = httpx.Client(timeout=30)

    def close(self) -> None:
        self._client.close()

    def login_patient(self, email: str, password: str) -> dict[str, Any] | None:
        response = self._client.post(
            f"{self.base_url}/api/users/login",
            json={"email": email, "password": password, "selectedOption": "Patient"},
        )
        if response.status_code in {400, 401, 403, 404}:
            return None
        response.raise_for_status()
        payload = response.json()
        return payload if isinstance(payload, dict) else None

    def register_patient(self, scenario: DemoScenario) -> dict[str, Any]:
        payload = auth_registration_payload(scenario)
        if self.dry_run:
            return {"dry_run": True, "payload": payload}
        response = self._client.post(
            f"{self.base_url}/api/users/PatientRegistration",
            json=payload,
        )
        try:
            response.raise_for_status()
        except httpx.HTTPStatusError as exc:
            raise RuntimeError(
                f"Failed to register auth patient {scenario.email}: "
                f"{response.status_code} {response.text}"
            ) from exc
        data = response.json()
        return data if isinstance(data, dict) else {"data": data}


class EHospitalSeedClient:
    def __init__(self, base_url: str, dry_run: bool = False) -> None:
        self.base_url = base_url.rstrip("/")
        self.dry_run = dry_run
        self._client = httpx.Client(timeout=30)

    def close(self) -> None:
        self._client.close()

    def select_one(self, table: str, field: str, value: Any) -> dict[str, Any] | None:
        rows = self.select_many(
            f"SELECT * FROM `{table}` WHERE `{field}` = :value LIMIT 1",
            {"value": value},
        )
        return rows[0] if rows else None

    def select_many(self, sql: str, replacements: dict[str, Any]) -> list[dict[str, Any]]:
        response = self._client.post(
            f"{self.base_url}/sql/select",
            json={"sql": sql, "replacements": replacements},
        )
        response.raise_for_status()
        payload = response.json()
        rows = payload.get("data", []) if isinstance(payload, dict) else []
        return [row for row in rows if isinstance(row, dict)]

    def insert_row(self, table: str, row: dict[str, Any]) -> dict[str, Any]:
        if self.dry_run:
            return {"dry_run": True, "table": table, "row": row}
        response = self._client.post(f"{self.base_url}/table/{table}", json=row)
        try:
            response.raise_for_status()
        except httpx.HTTPStatusError as exc:
            raise RuntimeError(
                f"Failed to insert row into {table}: "
                f"{response.status_code} {response.text}"
            ) from exc
        if not response.content:
            return {}
        payload = response.json()
        return payload if isinstance(payload, dict) else {"data": payload}


def iso_at(now: datetime, minutes_ago: int) -> str:
    return (now - timedelta(minutes=minutes_ago)).isoformat().replace("+00:00", "Z")


def auth_registration_payload(scenario: DemoScenario) -> dict[str, Any]:
    first_name, middle_name, last_name = patient_name_parts(scenario.name)
    return {
        "firstName": first_name,
        "middleName": middle_name,
        "lastName": last_name,
        "gender": scenario.gender,
        "age": scenario.age,
        "bloodGroup": scenario.blood_group,
        "mobileNumber": scenario.phone_number,
        "emailID": scenario.email,
        "cEmailID": scenario.email,
        "password": DEMO_PASSWORD,
        "cPassword": DEMO_PASSWORD,
        "address1": "75 Laurier Ave E",
        "address2": f"{scenario.key} demo suite",
        "postalCode": "K1N 6N5",
        "city": "Ottawa",
        "province": "Ontario",
        "healthCardNumber": f"{scenario.document_prefix}-HC",
        "passportNumber": f"{scenario.document_prefix}-PASS",
        "prNumber": f"{scenario.document_prefix}-PR",
        "drivingLicenseNumber": f"{scenario.document_prefix}-DL",
    }


def patient_name_parts(name: str) -> tuple[str, str, str]:
    parts = [part for part in name.split(" ") if part]
    if len(parts) >= 3:
        return parts[0], " ".join(parts[1:-1]), parts[-1]
    if len(parts) == 2:
        return parts[0], "", parts[1]
    return name, "", "Demo"


def ensure_auth_patient(
    client: EHospitalAuthSeedClient,
    scenario: DemoScenario,
) -> tuple[int, list[str]]:
    actions: list[str] = []
    patient = client.login_patient(scenario.email, DEMO_PASSWORD)
    if patient is None:
        client.register_patient(scenario)
        actions.append("registered auth patient")
        patient = client.login_patient(scenario.email, DEMO_PASSWORD)
    else:
        actions.append("reused auth patient")

    if client.dry_run and patient is None:
        actions.append("would register auth patient")
        return scenario.fallback_patient_id, actions
    if patient is None:
        raise RuntimeError(f"Unable to log in demo auth patient {scenario.email} after registration.")
    return parse_auth_patient_id(patient, scenario), actions


def parse_auth_patient_id(patient: dict[str, Any], scenario: DemoScenario) -> int:
    raw_id = patient.get("patient_id", patient.get("id", scenario.fallback_patient_id))
    try:
        return int(str(raw_id))
    except (TypeError, ValueError) as exc:
        raise RuntimeError(
            f"Auth patient {scenario.email} has non-numeric id {raw_id!r}; "
            "the Flutter login path expects a numeric patient id."
        ) from exc


def ensure_patient_profile(
    client: EHospitalSeedClient,
    scenario: DemoScenario,
    patient_id: int,
    now: datetime,
) -> list[str]:
    actions: list[str] = []
    user = client.select_one("users", "user_id", patient_id)
    if user is None:
        client.insert_row(
            "users",
            {
                "user_id": patient_id,
                "username": f"{scenario.username}_data",
                "email": data_service_email(scenario, patient_id),
                "password_hash": "auth-service-managed",
                "role": "patient",
                "created_on": now.date().isoformat(),
                "status": "active",
            },
        )
        actions.append("created data user")

    patient = client.select_one("patients_registration", "patient_id", patient_id)
    if patient is None:
        client.insert_row(
            "patients_registration",
            {
                "patient_id": patient_id,
                "name": scenario.name,
                "dob": scenario.dob,
                "gender": scenario.gender,
                "contact_info": scenario.email,
                "phone_number": scenario.phone_number,
                "OHIP_code": f"DEMO{patient_id}",
                "private_insurance_name": "Demo Insurance",
                "private_insurance_id": f"LLM-DEMO-{patient_id}",
                "weight_kg": 72,
                "height_cm": 170,
                "family_doctor_id": 1,
            },
        )
        actions.append("created patient registration")
    return actions


def data_service_email(scenario: DemoScenario, patient_id: int) -> str:
    local_part = scenario.email.split("@", 1)[0]
    return f"{local_part}.data{patient_id}@demo.com"


def has_recent_scenario_data(
    client: EHospitalSeedClient,
    patient_id: int,
    window_start: datetime,
) -> bool:
    checks = (
        "SELECT * FROM `wearable_vitals` WHERE `patient_id` = :patient_id "
        "AND (`timestamp` >= :window_start OR `recorded_on` >= :window_start) LIMIT 1",
        "SELECT * FROM `vitals_history` WHERE `patient_id` = :patient_id "
        "AND `recorded_on` >= :window_start LIMIT 1",
    )
    replacements = {
        "patient_id": patient_id,
        "window_start": window_start.isoformat().replace("+00:00", "Z"),
    }
    return any(client.select_many(sql, replacements) for sql in checks)


def seed_scenario_data(
    client: EHospitalSeedClient,
    scenario: DemoScenario,
    patient_id: int,
    now: datetime,
) -> list[str]:
    return [
        *seed_context_data(client, scenario, patient_id, now),
        *seed_recent_measurements(client, scenario, patient_id, now),
    ]


def seed_recent_measurements(
    client: EHospitalSeedClient,
    scenario: DemoScenario,
    patient_id: int,
    now: datetime,
) -> list[str]:
    actions: list[str] = []
    for row in scenario.wearable_rows:
        timestamp = iso_at(now, int(row["minutes_ago"]))
        client.insert_row(
            "wearable_vitals",
            {
                "patient_id": patient_id,
                "heart_rate": row["heart_rate"],
                "steps": row["steps"],
                "calories": row["calories"],
                "sleep": row["sleep"],
                "timestamp": timestamp,
                "recorded_on": timestamp,
            },
        )
    if scenario.wearable_rows:
        actions.append(f"inserted {len(scenario.wearable_rows)} wearable rows")

    for row in scenario.vitals_rows:
        recorded_on = iso_at(now, int(row["minutes_ago"]))
        client.insert_row(
            "vitals_history",
            {
                "patient_id": patient_id,
                "blood_pressure": row["blood_pressure"],
                "heart_rate": row["heart_rate"],
                "temperature": 36.7,
                "respiratory_rate": 16,
                "recorded_on": recorded_on,
                "notes": vitals_note_for_row(scenario, row),
            },
        )
    if scenario.vitals_rows:
        actions.append(f"inserted {len(scenario.vitals_rows)} vitals rows")
    return actions


def seed_context_data(
    client: EHospitalSeedClient,
    scenario: DemoScenario,
    patient_id: int,
    now: datetime,
) -> list[str]:
    actions: list[str] = []
    for row in scenario.diagnosis_rows:
        if context_exists(client, "diagnosis", patient_id, "diagnosis_code", row.get("diagnosis_code")):
            continue
        client.insert_row(
            "diagnosis",
            {"diagnosis_id": patient_id * 100 + 1, "patient_id": patient_id, **row},
        )
    if scenario.diagnosis_rows:
        actions.append("ensured diagnosis context")

    for row in scenario.medical_history_rows:
        if context_exists(client, "medical_history", patient_id, "condition", row.get("condition")):
            continue
        client.insert_row(
            "medical_history",
            {
                "history_id": patient_id * 100 + 1,
                "patient_id": patient_id,
                "last_updated": now.date().isoformat(),
                **row,
            },
        )
    if scenario.medical_history_rows:
        actions.append("ensured medical history context")

    for row in scenario.prescription_form_rows:
        if context_exists(
            client,
            "prescription_form",
            patient_id,
            "medication_name",
            row.get("medication_name"),
        ):
            continue
        client.insert_row(
            "prescription_form",
            {"prescription_id": patient_id * 100 + 1, "patient_id": patient_id, **row},
        )
    if scenario.prescription_form_rows:
        actions.append("ensured prescription context")

    return actions


def vitals_note_for_row(scenario: DemoScenario, row: dict[str, Any]) -> str:
    note = f"{DEMO_MARKER}:{scenario.key}; generated for 3-hour LLM analysis."
    symptom_note = row.get("symptom_note")
    if isinstance(symptom_note, str) and symptom_note.strip():
        return f"{note} {symptom_note.strip()}"
    return note


def context_exists(
    client: EHospitalSeedClient,
    table: str,
    patient_id: int,
    field: str,
    value: Any,
) -> bool:
    if value is None:
        return False
    rows = client.select_many(
        f"SELECT * FROM `{table}` WHERE `patient_id` = :patient_id "
        f"AND `{field}` = :value LIMIT 1",
        {"patient_id": patient_id, "value": value},
    )
    return bool(rows)


def seed_all(
    base_url: str,
    auth_base_url: str,
    dry_run: bool,
    window_hours: int,
    refresh_recent: bool = False,
) -> dict[str, Any]:
    now = datetime.now(UTC).replace(microsecond=0)
    window_start = now - timedelta(hours=window_hours)
    client = EHospitalSeedClient(base_url, dry_run=dry_run)
    auth_client = EHospitalAuthSeedClient(auth_base_url, dry_run=dry_run)
    try:
        results = []
        for scenario in DEMO_SCENARIOS:
            patient_id, actions = ensure_auth_patient(auth_client, scenario)
            actions.extend(ensure_patient_profile(client, scenario, patient_id, now))
            actions.extend(seed_context_data(client, scenario, patient_id, now))
            if not refresh_recent and has_recent_scenario_data(client, patient_id, window_start):
                scenario_actions = [*actions, "skipped recent scenario data already exists"]
                inserted = False
            else:
                scenario_actions = [
                    *actions,
                    *seed_recent_measurements(client, scenario, patient_id, now),
                ]
                inserted = True
            results.append(
                {
                    "scenario": scenario.key,
                    "email": scenario.email,
                    "password": DEMO_PASSWORD,
                    "patient_id": patient_id,
                    "fallback_patient_id": scenario.fallback_patient_id,
                    "inserted_recent_data": inserted,
                    "actions": scenario_actions,
                }
            )
        return {
            "base_url": base_url,
            "auth_base_url": auth_base_url,
            "refresh_recent": refresh_recent,
            "window_start": window_start.isoformat().replace("+00:00", "Z"),
            "window_end": now.isoformat().replace("+00:00", "Z"),
            "patients": results,
        }
    finally:
        client.close()
        auth_client.close()


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Create fixed LLM demo patients and seed recent scenario data."
    )
    parser.add_argument(
        "--base-url",
        default=os.getenv("EHOSPITAL_BASE_URL", DEFAULT_BASE_URL),
        help="eHospital API base URL. Defaults to EHOSPITAL_BASE_URL or production demo URL.",
    )
    parser.add_argument(
        "--auth-base-url",
        default=os.getenv("EHOSPITAL_AUTH_BASE_URL", DEFAULT_AUTH_BASE_URL),
        help="eHospital auth API base URL. Defaults to EHOSPITAL_AUTH_BASE_URL or production auth URL.",
    )
    parser.add_argument(
        "--window-hours",
        type=int,
        default=DEFAULT_WINDOW_HOURS,
        help="Recent-data idempotency window. Defaults to 3.",
    )
    parser.add_argument("--dry-run", action="store_true", help="Print intended inserts without writing rows.")
    parser.add_argument(
        "--refresh-recent",
        action="store_true",
        help="Insert a fresh 3-hour scenario window even when recent data exists.",
    )
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv or sys.argv[1:])
    result = seed_all(
        args.base_url,
        args.auth_base_url,
        dry_run=args.dry_run,
        window_hours=args.window_hours,
        refresh_recent=args.refresh_recent,
    )
    print(json.dumps(result, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
