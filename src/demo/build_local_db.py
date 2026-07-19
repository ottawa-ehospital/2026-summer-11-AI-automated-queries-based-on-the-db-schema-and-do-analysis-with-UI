from __future__ import annotations

import csv
import json
import math
from collections import Counter, defaultdict
from datetime import datetime
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parent
DATASETS = ROOT / "datasets"
LOCAL_DB = ROOT / "local_db"
FITBIT = (
    DATASETS
    / "archive (1)"
    / "mturkfitbit_export_4.12.16-5.12.16"
    / "Fitabase Data 4.12.16-5.12.16"
)

DEMO_USERS = [
    {
        "user_id": "u_001",
        "username": "john",
        "password": "john123",
        "display_name": "John Doe",
        "email": "john.doe@example.com",
        "source_fitbit_id": "1503960366",
    },
    {
        "user_id": "u_002",
        "username": "jane",
        "password": "jane123",
        "display_name": "Jane Smith",
        "email": "jane.smith@example.com",
        "source_fitbit_id": "1624580081",
    },
    {
        "user_id": "u_003",
        "username": "alex",
        "password": "alex123",
        "display_name": "Alex Chen",
        "email": "alex.chen@example.com",
        "source_fitbit_id": "1644430081",
    },
    {
        "user_id": "u_004",
        "username": "maria",
        "password": "maria123",
        "display_name": "Maria Garcia",
        "email": "maria.garcia@example.com",
        "source_fitbit_id": "1844505072",
    },
    {
        "user_id": "u_005",
        "username": "sam",
        "password": "sam123",
        "display_name": "Sam Patel",
        "email": "sam.patel@example.com",
        "source_fitbit_id": "1927972279",
    },
    {
        "user_id": "u_006",
        "username": "lisa",
        "password": "lisa123",
        "display_name": "Lisa Brown",
        "email": "lisa.brown@example.com",
        "source_fitbit_id": "2022484408",
    },
]

PROFILE_NAMES = {
    "u_001": ("John Doe", "Male"),
    "u_002": ("Jane Smith", "Female"),
    "u_003": ("Alex Chen", "Male"),
    "u_004": ("Maria Garcia", "Female"),
    "u_005": ("Sam Patel", "Male"),
    "u_006": ("Lisa Brown", "Female"),
}


def read_csv(path: Path) -> list[dict[str, str]]:
    with path.open("r", encoding="utf-8-sig", newline="") as file:
        return list(csv.DictReader(file))


def write_json(name: str, rows: list[dict[str, Any]]) -> None:
    path = LOCAL_DB / name
    with path.open("w", encoding="utf-8") as file:
        json.dump(rows, file, indent=2, ensure_ascii=False)
        file.write("\n")


def to_int(value: Any, default: int = 0) -> int:
    if value in (None, ""):
        return default
    return int(float(value))


def to_float(value: Any, default: float = 0.0, digits: int = 2) -> float:
    if value in (None, ""):
        return default
    parsed = float(value)
    if math.isnan(parsed):
        return default
    return round(parsed, digits)


def parse_datetime(value: str) -> datetime:
    for fmt in ("%m/%d/%Y %I:%M:%S %p", "%m/%d/%Y"):
        try:
            return datetime.strptime(value, fmt)
        except ValueError:
            continue
    raise ValueError(f"Unsupported date format: {value}")


def date_text(value: str) -> str:
    return parse_datetime(value).date().isoformat()


def hour_int(value: str) -> int:
    return parse_datetime(value).hour


def rows_by_id(rows: list[dict[str, str]], id_key: str = "Id") -> dict[str, list[dict[str, str]]]:
    grouped: dict[str, list[dict[str, str]]] = defaultdict(list)
    for row in rows:
        grouped[row[id_key]].append(row)
    return grouped


def pick_by_index(rows: list[dict[str, str]], index: int) -> dict[str, str]:
    return rows[index % len(rows)]


def build_users() -> list[dict[str, Any]]:
    return [
        {
            "user_id": user["user_id"],
            "username": user["username"],
            "password": user["password"],
            "display_name": user["display_name"],
            "email": user["email"],
            "created_at": "2026-05-31T00:00:00Z",
        }
        for user in DEMO_USERS
    ]


def build_exercise_catalog(mega_rows: list[dict[str, str]]) -> list[dict[str, Any]]:
    catalog = []
    for index, row in enumerate(mega_rows[:240], start=1):
        catalog.append(
            {
                "exercise_id": f"ex_{index:04d}",
                "title": row["Title"],
                "description": row["Desc"],
                "type": row["Type"] or "Strength",
                "body_part": row["BodyPart"],
                "equipment": row["Equipment"],
                "level": row["Level"] or "Beginner",
                "rating": to_float(row["Rating"], 0.0, 1),
            }
        )
    return catalog


def build_user_profiles(
    sleep_rows: list[dict[str, str]], gym_rows: list[dict[str, str]]
) -> list[dict[str, Any]]:
    profiles = []
    for index, user in enumerate(DEMO_USERS):
        name, gender = PROFILE_NAMES[user["user_id"]]
        matching_sleep = [
            row for row in sleep_rows if row["Gender"].lower() == gender.lower()
        ]
        sleep_row = pick_by_index(matching_sleep or sleep_rows, index)
        gym_row = pick_by_index(gym_rows, index * 7)
        profiles.append(
            {
                "user_id": user["user_id"],
                "name": name,
                "gender": gender,
                "age": to_int(sleep_row["Age"]),
                "occupation": sleep_row["Occupation"],
                "experience_level": to_int(gym_row["Experience_Level"], 1),
            }
        )
    return profiles


def build_body_metrics(
    gym_rows: list[dict[str, str]],
    sleep_rows: list[dict[str, str]],
    weight_by_id: dict[str, list[dict[str, str]]],
) -> list[dict[str, Any]]:
    metrics = []
    for index, user in enumerate(DEMO_USERS):
        gym_row = pick_by_index(gym_rows, index * 13)
        sleep_row = pick_by_index(sleep_rows, index * 11)
        weight_rows = weight_by_id.get(user["source_fitbit_id"], [])
        weight_row = weight_rows[-1] if weight_rows else None
        height_m = to_float(gym_row["Height (m)"], 1.7, 2)
        weight_kg = (
            to_float(weight_row["WeightKg"], 0.0, 2)
            if weight_row
            else to_float(gym_row["Weight (kg)"], 70.0, 2)
        )
        bmi = round(weight_kg / (height_m * height_m), 2)
        metrics.append(
            {
                "metric_id": f"bm_{index + 1:03d}",
                "user_id": user["user_id"],
                "recorded_date": date_text(weight_row["Date"]) if weight_row else "2016-05-12",
                "height_m": height_m,
                "weight_kg": weight_kg,
                "bmi": bmi,
                "fat_percentage": to_float(gym_row["Fat_Percentage"], 0.0, 1),
                "blood_pressure": sleep_row["Blood Pressure"],
                "resting_bpm": to_int(gym_row["Resting_BPM"]),
            }
        )
    return metrics


def build_daily_activity(
    daily_by_id: dict[str, list[dict[str, str]]]
) -> list[dict[str, Any]]:
    rows = []
    sequence = 1
    for user in DEMO_USERS:
        source_rows = daily_by_id.get(user["source_fitbit_id"], [])[:14]
        for row in source_rows:
            rows.append(
                {
                    "activity_id": f"da_{sequence:04d}",
                    "user_id": user["user_id"],
                    "date": date_text(row["ActivityDate"]),
                    "total_steps": to_int(row["TotalSteps"]),
                    "total_distance_km": to_float(row["TotalDistance"], 0.0, 2),
                    "very_active_minutes": to_int(row["VeryActiveMinutes"]),
                    "fairly_active_minutes": to_int(row["FairlyActiveMinutes"]),
                    "lightly_active_minutes": to_int(row["LightlyActiveMinutes"]),
                    "sedentary_minutes": to_int(row["SedentaryMinutes"]),
                    "calories": to_int(row["Calories"]),
                }
            )
            sequence += 1
    return rows


def build_hourly_activity(
    hourly_steps: list[dict[str, str]],
    hourly_calories: list[dict[str, str]],
    hourly_intensities: list[dict[str, str]],
    daily_activity: list[dict[str, Any]],
) -> list[dict[str, Any]]:
    desired = {(row["user_id"], row["date"]) for row in daily_activity}
    source_to_user = {user["source_fitbit_id"]: user["user_id"] for user in DEMO_USERS}
    calories_map = {
        (row["Id"], date_text(row["ActivityHour"]), hour_int(row["ActivityHour"])): row
        for row in hourly_calories
    }
    intensity_map = {
        (row["Id"], date_text(row["ActivityHour"]), hour_int(row["ActivityHour"])): row
        for row in hourly_intensities
    }
    rows = []
    sequence = 1
    for step_row in hourly_steps:
        user_id = source_to_user.get(step_row["Id"])
        if not user_id:
            continue
        date = date_text(step_row["ActivityHour"])
        if (user_id, date) not in desired:
            continue
        hour = hour_int(step_row["ActivityHour"])
        key = (step_row["Id"], date, hour)
        calories_row = calories_map.get(key, {})
        intensity_row = intensity_map.get(key, {})
        rows.append(
            {
                "hourly_id": f"ha_{sequence:05d}",
                "user_id": user_id,
                "date": date,
                "hour": hour,
                "steps": to_int(step_row["StepTotal"]),
                "calories": to_int(calories_row.get("Calories", 0)),
                "total_intensity": to_int(intensity_row.get("TotalIntensity", 0)),
                "average_intensity": to_float(
                    intensity_row.get("AverageIntensity", 0.0), 0.0, 4
                ),
            }
        )
        sequence += 1
    return rows


def build_sleep_records(
    lifestyle_rows: list[dict[str, str]],
    sleep_by_id: dict[str, list[dict[str, str]]],
) -> list[dict[str, Any]]:
    rows = []
    sequence = 1
    for index, user in enumerate(DEMO_USERS):
        lifestyle = pick_by_index(lifestyle_rows, index * 9)
        source_rows = sleep_by_id.get(user["source_fitbit_id"], [])[:14]
        if not source_rows:
            source_rows = [{"SleepDay": "5/1/2016 12:00:00 AM", "TotalSleepRecords": "1", "TotalMinutesAsleep": str(int(float(lifestyle["Sleep Duration"]) * 60)), "TotalTimeInBed": str(int(float(lifestyle["Sleep Duration"]) * 60) + 20)}]
        for row in source_rows:
            minutes_asleep = to_int(row["TotalMinutesAsleep"])
            rows.append(
                {
                    "sleep_id": f"sl_{sequence:04d}",
                    "user_id": user["user_id"],
                    "date": date_text(row["SleepDay"]),
                    "sleep_duration_hours": round(minutes_asleep / 60, 2),
                    "quality_of_sleep": to_int(lifestyle["Quality of Sleep"]),
                    "total_sleep_records": to_int(row["TotalSleepRecords"], 1),
                    "minutes_asleep": minutes_asleep,
                    "time_in_bed_minutes": to_int(row["TotalTimeInBed"]),
                    "stress_level": to_int(lifestyle["Stress Level"]),
                    "sleep_disorder": lifestyle["Sleep Disorder"],
                }
            )
            sequence += 1
    return rows


def build_workout_sessions(gym_rows: list[dict[str, str]]) -> list[dict[str, Any]]:
    rows = []
    sequence = 1
    dates_by_user = {
        user["user_id"]: [f"2016-04-{day:02d}" for day in range(12, 26)]
        for user in DEMO_USERS
    }
    for user_index, user in enumerate(DEMO_USERS):
        for workout_index in range(5):
            row = pick_by_index(gym_rows, user_index * 17 + workout_index * 3)
            rows.append(
                {
                    "session_id": f"ws_{sequence:04d}",
                    "user_id": user["user_id"],
                    "date": dates_by_user[user["user_id"]][workout_index * 2],
                    "workout_type": row["Workout_Type"],
                    "duration_hours": to_float(row["Session_Duration (hours)"], 1.0, 2),
                    "avg_bpm": to_int(row["Avg_BPM"]),
                    "max_bpm": to_int(row["Max_BPM"]),
                    "calories_burned": to_int(row["Calories_Burned"]),
                    "water_intake_liters": to_float(row["Water_Intake (liters)"], 2.0, 1),
                }
            )
            sequence += 1
    return rows


def build_session_exercises(
    workout_sessions: list[dict[str, Any]],
    exercise_catalog: list[dict[str, Any]],
) -> list[dict[str, Any]]:
    rows = []
    sequence = 1
    catalog_by_type: dict[str, list[dict[str, Any]]] = defaultdict(list)
    for exercise in exercise_catalog:
        catalog_by_type[exercise["type"].lower()].append(exercise)
    strength_pool = catalog_by_type.get("strength", exercise_catalog)
    cardio_pool = catalog_by_type.get("cardio", exercise_catalog)
    for session_index, session in enumerate(workout_sessions):
        pool = cardio_pool if session["workout_type"].lower() == "cardio" else strength_pool
        for offset in range(3):
            exercise = pool[(session_index * 3 + offset) % len(pool)]
            rows.append(
                {
                    "session_exercise_id": f"se_{sequence:05d}",
                    "session_id": session["session_id"],
                    "exercise_id": exercise["exercise_id"],
                    "sets": 3 if session["workout_type"].lower() != "cardio" else 1,
                    "reps": 12 if session["workout_type"].lower() != "cardio" else None,
                    "duration_minutes": 10 + offset * 5,
                }
            )
            sequence += 1
    return rows


def build_summaries(
    body_metrics: list[dict[str, Any]],
    daily_activity: list[dict[str, Any]],
    sleep_records: list[dict[str, Any]],
    workout_sessions: list[dict[str, Any]],
) -> list[dict[str, Any]]:
    summaries = []
    for user in DEMO_USERS:
        user_id = user["user_id"]
        body = next(row for row in body_metrics if row["user_id"] == user_id)
        daily = [row for row in daily_activity if row["user_id"] == user_id]
        sleep = [row for row in sleep_records if row["user_id"] == user_id]
        workouts = [row for row in workout_sessions if row["user_id"] == user_id]
        workout_type = Counter(row["workout_type"] for row in workouts).most_common(1)[0][0]
        avg_sleep = round(sum(row["sleep_duration_hours"] for row in sleep) / len(sleep), 2)
        avg_steps = round(sum(row["total_steps"] for row in daily) / len(daily))
        avg_calories = round(sum(row["calories"] for row in daily) / len(daily))
        risk_notes = []
        if avg_sleep < 6.5:
            risk_notes.append("average sleep is below 6.5 hours")
        if body["bmi"] >= 30:
            risk_notes.append("BMI is in the obese range")
        if avg_steps < 5000:
            risk_notes.append("daily steps are relatively low")
        summaries.append(
            {
                "user_id": user_id,
                "latest_weight_kg": body["weight_kg"],
                "latest_bmi": body["bmi"],
                "avg_sleep_hours": avg_sleep,
                "avg_daily_steps": avg_steps,
                "avg_daily_calories": avg_calories,
                "primary_workout_type": workout_type,
                "latest_sleep_quality": sleep[-1]["quality_of_sleep"],
                "risk_notes": risk_notes or ["no major demo risk notes"],
            }
        )
    return summaries


def main() -> None:
    LOCAL_DB.mkdir(parents=True, exist_ok=True)

    gym_rows = read_csv(DATASETS / "gym_members_exercise_tracking.csv")
    mega_rows = read_csv(DATASETS / "megaGymDataset.csv")
    lifestyle_rows = read_csv(DATASETS / "Sleep_health_and_lifestyle_dataset.csv")
    daily_rows = read_csv(FITBIT / "dailyActivity_merged.csv")
    sleep_rows = read_csv(FITBIT / "sleepDay_merged.csv")
    weight_rows = read_csv(FITBIT / "weightLogInfo_merged.csv")
    hourly_steps = read_csv(FITBIT / "hourlySteps_merged.csv")
    hourly_calories = read_csv(FITBIT / "hourlyCalories_merged.csv")
    hourly_intensities = read_csv(FITBIT / "hourlyIntensities_merged.csv")

    users = build_users()
    profiles = build_user_profiles(lifestyle_rows, gym_rows)
    exercise_catalog = build_exercise_catalog(mega_rows)
    body_metrics = build_body_metrics(gym_rows, lifestyle_rows, rows_by_id(weight_rows))
    daily_activity = build_daily_activity(rows_by_id(daily_rows))
    hourly_activity = build_hourly_activity(
        hourly_steps, hourly_calories, hourly_intensities, daily_activity
    )
    sleep_records = build_sleep_records(lifestyle_rows, rows_by_id(sleep_rows))
    workout_sessions = build_workout_sessions(gym_rows)
    workout_session_exercises = build_session_exercises(workout_sessions, exercise_catalog)
    summaries = build_summaries(
        body_metrics, daily_activity, sleep_records, workout_sessions
    )

    tables = {
        "users.json": users,
        "user_profiles.json": profiles,
        "body_metrics.json": body_metrics,
        "daily_activity.json": daily_activity,
        "hourly_activity.json": hourly_activity,
        "sleep_records.json": sleep_records,
        "workout_sessions.json": workout_sessions,
        "exercise_catalog.json": exercise_catalog,
        "workout_session_exercises.json": workout_session_exercises,
        "user_health_summary.json": summaries,
    }
    for name, rows in tables.items():
        write_json(name, rows)
        print(f"{name}: {len(rows)} rows")


if __name__ == "__main__":
    main()
