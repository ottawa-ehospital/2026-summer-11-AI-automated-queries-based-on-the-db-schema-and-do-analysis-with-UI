from datetime import UTC, datetime, timedelta

from src.datasets import seed_llm_health_scenarios as seed


class FakeSeedClient:
    def __init__(self):
        self.rows = {
            "users": [],
            "patients_registration": [],
            "wearable_vitals": [],
            "vitals_history": [],
            "diagnosis": [],
            "medical_history": [],
            "prescription_form": [],
        }

    def select_one(self, table, field, value):
        return next(
            (row for row in self.rows[table] if str(row.get(field)) == str(value)),
            None,
        )

    def select_many(self, sql, replacements):
        table = sql.split("`")[1]
        patient_id = str(replacements.get("patient_id", ""))
        window_start = replacements.get("window_start")
        rows = [
            row
            for row in self.rows.get(table, [])
            if str(row.get("patient_id")) == patient_id
        ]
        if not window_start:
            return rows
        date_fields = ("timestamp", "recorded_on", "datetime")
        return [
            row
            for row in rows
            if any(str(row.get(field, "")) >= window_start for field in date_fields)
        ]

    def insert_row(self, table, row):
        self.rows[table].append(row)
        return {"ok": True}


class FakeAuthClient:
    def __init__(self, patient=None):
        self.patient = patient
        self.registered = []
        self.dry_run = False

    def login_patient(self, email, password):
        return self.patient

    def register_patient(self, scenario):
        self.registered.append(scenario.email)
        self.patient = {"id": 391, "EmailId": scenario.email}
        return {"message": "Operation successful"}


def test_ensure_auth_patient_registers_then_uses_login_id():
    fake = FakeAuthClient()

    patient_id, actions = seed.ensure_auth_patient(fake, seed.DEMO_SCENARIOS[0])

    assert patient_id == 391
    assert actions == ["registered auth patient"]
    assert fake.registered == ["normal@demo.com"]


def test_ensure_patient_profile_uses_auth_patient_id():
    fake = FakeSeedClient()
    now = datetime(2026, 7, 2, 12, 0, tzinfo=UTC)

    actions = seed.ensure_patient_profile(
        fake,
        seed.DEMO_SCENARIOS[0],
        patient_id=391,
        now=now,
    )

    assert actions == ["created data user", "created patient registration"]
    assert fake.rows["users"][0]["user_id"] == 391
    assert fake.rows["users"][0]["email"] == "normal.data391@demo.com"
    assert fake.rows["patients_registration"][0]["patient_id"] == 391
    assert fake.rows["patients_registration"][0]["contact_info"] == "normal@demo.com"


def test_demo_scenarios_only_include_normal_and_hypertension_users():
    assert [scenario.key for scenario in seed.DEMO_SCENARIOS] == [
        "normal",
        "hypertension_med_symptom",
    ]
    assert [scenario.email for scenario in seed.DEMO_SCENARIOS] == [
        "normal@demo.com",
        "hypertension@demo.com",
    ]
    assert all(len(scenario.wearable_rows) == 12 for scenario in seed.DEMO_SCENARIOS)
    assert all(len(scenario.vitals_rows) == 7 for scenario in seed.DEMO_SCENARIOS)


def test_recent_scenario_data_blocks_duplicate_seed():
    fake = FakeSeedClient()
    now = datetime(2026, 7, 2, 12, 0, tzinfo=UTC)
    fake.rows["wearable_vitals"].append(
        {
            "patient_id": 391,
            "timestamp": (now - timedelta(minutes=10)).isoformat().replace("+00:00", "Z"),
        }
    )

    assert seed.has_recent_scenario_data(fake, 391, now - timedelta(hours=3))


def test_seed_scenario_data_includes_medication_and_symptom_context():
    fake = FakeSeedClient()
    now = datetime(2026, 7, 2, 12, 0, tzinfo=UTC)

    actions = seed.seed_scenario_data(
        fake,
        seed.DEMO_SCENARIOS[1],
        patient_id=393,
        now=now,
    )

    assert "ensured prescription context" in actions
    assert "inserted 12 wearable rows" in actions
    assert "inserted 7 vitals rows" in actions
    assert fake.rows["prescription_form"][0]["prescription_id"] == 39301
    assert fake.rows["prescription_form"][0]["medication_name"] == "Amlodipine"
    notes = [row["notes"] for row in fake.rows["vitals_history"]]
    assert any("headache" in note and "mild dizziness" in note for note in notes)
    assert any("headache severity 5/10" in note for note in notes)
