from __future__ import annotations

import json
import operator
import os
import random
from functools import lru_cache
from pathlib import Path
from typing import Annotated, Any, Literal

from dotenv import load_dotenv
from langchain.chat_models import init_chat_model
from langchain.messages import AnyMessage, HumanMessage, SystemMessage, ToolMessage
from langchain.tools import tool
from langchain_openai import ChatOpenAI
from langgraph.graph import END, START, StateGraph
from typing_extensions import TypedDict


load_dotenv()

LOCAL_DB = Path(__file__).resolve().parent / "local_db"

model_provider = os.getenv("MODEL_PROVIDER", "openai").lower()
model_name = os.getenv("MODEL_NAME", "gpt-4o-mini")

if model_provider == "ollama":
    model = ChatOpenAI(
        model=model_name,
        base_url=os.getenv("OLLAMA_BASE_URL", "http://localhost:11434/v1"),
        api_key=os.getenv("OLLAMA_API_KEY", "ollama"),
        temperature=0,
    )
else:
    model = init_chat_model(
        model_name,
        temperature=0,
    )


class MessagesState(TypedDict):
    messages: Annotated[list[AnyMessage], operator.add]
    llm_calls: int


TABLE_ALIASES = {
    "activity": "daily_activity",
    "activities": "daily_activity",
    "body": "body_metrics",
    "body_metric": "body_metrics",
    "body_metrics": "body_metrics",
    "daily": "daily_activity",
    "daily_activity": "daily_activity",
    "daily_checkin": "daily_checkins",
    "daily_checkins": "daily_checkins",
    "exercise": "exercise_catalog",
    "exercise_catalog": "exercise_catalog",
    "exercises": "exercise_catalog",
    "fitness": "workout_sessions",
    "fitness_readiness": "fitness_readiness",
    "health": "user_health_summary",
    "hourly": "hourly_activity",
    "hourly_activity": "hourly_activity",
    "profile": "user_profiles",
    "profiles": "user_profiles",
    "sleep": "sleep_records",
    "sleep_records": "sleep_records",
    "summary": "user_health_summary",
    "user": "user_profiles",
    "user_health_summary": "user_health_summary",
    "user_profile": "user_profiles",
    "user_profiles": "user_profiles",
    "users": "user_profiles",
    "weight": "body_metrics",
    "workout": "workout_sessions",
    "workout_sessions": "workout_sessions",
    "workouts": "workout_sessions",
    "readiness": "fitness_readiness",
}

USER_TABLES = {
    "body_metrics",
    "daily_checkins",
    "daily_activity",
    "fitness_readiness",
    "hourly_activity",
    "sleep_records",
    "user_health_summary",
    "user_profiles",
    "workout_sessions",
}


@lru_cache(maxsize=None)
def load_table(table_name: str) -> list[dict[str, Any]]:
    path = LOCAL_DB / f"{table_name}.json"
    if not path.exists():
        return []
    with path.open("r", encoding="utf-8") as file:
        return json.load(file)


def save_table(table_name: str, rows: list[dict[str, Any]]) -> None:
    LOCAL_DB.mkdir(parents=True, exist_ok=True)
    path = LOCAL_DB / f"{table_name}.json"
    with path.open("w", encoding="utf-8") as file:
        json.dump(rows, file, indent=2, ensure_ascii=False)
        file.write("\n")
    load_table.cache_clear()


def normalize_db_name(db_name: str) -> str:
    cleaned = db_name.strip().lower().replace(" ", "_")
    return TABLE_ALIASES.get(cleaned, cleaned)


def available_tables() -> list[str]:
    return sorted(TABLE_ALIASES.keys() | USER_TABLES | {"exercise_catalog"})


def _without_password(row: dict[str, Any]) -> dict[str, Any]:
    return {key: value for key, value in row.items() if key != "password"}


def _latest_for_user(table_name: str, user_id: str) -> dict[str, Any] | None:
    rows = [row for row in load_table(table_name) if row.get("user_id") == user_id]
    if not rows:
        return None
    return rows[-1]


def _rows_for_user(table_name: str, user_id: str, limit: int | None = None) -> list[dict[str, Any]]:
    rows = [row for row in load_table(table_name) if row.get("user_id") == user_id]
    return rows[-limit:] if limit else rows


def _session_exercises_for_user(user_id: str) -> list[dict[str, Any]]:
    sessions = _rows_for_user("workout_sessions", user_id)
    session_ids = {session["session_id"] for session in sessions}
    exercises_by_id = {
        exercise["exercise_id"]: exercise for exercise in load_table("exercise_catalog")
    }
    rows = []
    for row in load_table("workout_session_exercises"):
        if row["session_id"] not in session_ids:
            continue
        exercise = exercises_by_id.get(row["exercise_id"], {})
        rows.append(
            {
                **row,
                "exercise_title": exercise.get("title"),
                "body_part": exercise.get("body_part"),
                "equipment": exercise.get("equipment"),
            }
        )
    return rows


def get_profile_by_user_id(user_id: str) -> dict[str, Any] | None:
    user = next((row for row in load_table("users") if row["user_id"] == user_id), None)
    profile = _latest_for_user("user_profiles", user_id)
    body = _latest_for_user("body_metrics", user_id)
    summary = _latest_for_user("user_health_summary", user_id)
    if user is None or profile is None or body is None:
        return None

    return {
        **_without_password(user),
        **profile,
        "weight": body["weight_kg"],
        "height": body["height_m"],
        "bmi": body["bmi"],
        "fat_percentage": body["fat_percentage"],
        "resting_bpm": body["resting_bpm"],
        "health_summary": summary,
    }


def list_public_users() -> list[dict[str, Any]]:
    return [
        profile
        for user in load_table("users")
        if (profile := get_profile_by_user_id(user["user_id"])) is not None
    ]


def current_user_context(user_id: str) -> dict[str, Any]:
    profile = get_profile_by_user_id(user_id)
    if profile is None:
        raise ValueError(f"Unknown user_id: {user_id}")
    return {
        "user": profile,
        "latest_body_metrics": _latest_for_user("body_metrics", user_id),
        "health_summary": _latest_for_user("user_health_summary", user_id),
        "current_checkin": _latest_for_user("daily_checkins", user_id),
        "fitness_readiness": _latest_for_user("fitness_readiness", user_id),
        "recent_daily_activity": _rows_for_user("daily_activity", user_id, limit=7),
        "recent_sleep_records": _rows_for_user("sleep_records", user_id, limit=7),
        "recent_workout_sessions": _rows_for_user("workout_sessions", user_id, limit=5),
    }


def get_dashboard_for_user(user_id: str) -> dict[str, Any] | None:
    user = get_profile_by_user_id(user_id)
    if user is None:
        return None

    summary = _latest_for_user("user_health_summary", user_id)
    daily_activity = [
        {
            "date": row["date"],
            "steps": row["total_steps"],
            "calories": row["calories"],
            "very_active_minutes": row["very_active_minutes"],
            "fairly_active_minutes": row["fairly_active_minutes"],
            "lightly_active_minutes": row["lightly_active_minutes"],
        }
        for row in _rows_for_user("daily_activity", user_id, limit=14)
    ]
    workout_sessions = [
        {
            "date": row["date"],
            "workout_type": row["workout_type"],
            "duration_hours": row["duration_hours"],
            "calories_burned": row["calories_burned"],
            "avg_bpm": row["avg_bpm"],
        }
        for row in _rows_for_user("workout_sessions", user_id, limit=10)
    ]
    sleep_records = [
        {
            "date": row["date"],
            "sleep_duration_hours": row["sleep_duration_hours"],
            "quality_of_sleep": row["quality_of_sleep"],
            "stress_level": row["stress_level"],
            "minutes_asleep": row["minutes_asleep"],
            "time_in_bed_minutes": row["time_in_bed_minutes"],
        }
        for row in _rows_for_user("sleep_records", user_id, limit=14)
    ]
    body_metric = _latest_for_user("body_metrics", user_id)

    return {
        "user": user,
        "summary": summary,
        "current": {
            "daily_checkin": _latest_for_user("daily_checkins", user_id),
            "fitness_readiness": _latest_for_user("fitness_readiness", user_id),
        },
        "fitness": {
            "daily_activity": daily_activity,
            "workout_sessions": workout_sessions,
        },
        "sleep": {
            "records": sleep_records,
        },
        "body": {
            "metrics": body_metric,
        },
    }


def query_local_table(table_name: str, user_id: str) -> Any:
    normalized = normalize_db_name(table_name)
    if normalized == "all":
        return current_user_context(user_id)
    if normalized == "workout_session_exercises":
        return _session_exercises_for_user(user_id)
    if normalized == "exercise_catalog":
        return load_table("exercise_catalog")[:60]
    if normalized in USER_TABLES:
        return _rows_for_user(normalized, user_id)
    raise ValueError(f"Unknown table '{table_name}'. Available tables: {available_tables()}")


def _bounded_int(value: Any, default: int, minimum: int, maximum: int) -> int:
    if value is None:
        return default
    return max(minimum, min(maximum, int(value)))


def _range_value(
    ranges: dict[str, Any],
    key: str,
    default_min: int,
    default_max: int,
    absolute_min: int,
    absolute_max: int,
    rng: random.Random,
) -> int:
    raw = ranges.get(key, {})
    lower = _bounded_int(raw.get("min"), default_min, absolute_min, absolute_max)
    upper = _bounded_int(raw.get("max"), default_max, absolute_min, absolute_max)
    if lower > upper:
        lower, upper = upper, lower
    return rng.randint(lower, upper)


def _upsert_current_row(table_name: str, row: dict[str, Any]) -> dict[str, Any]:
    rows = load_table(table_name)
    filtered = [
        item
        for item in rows
        if not (item.get("user_id") == row["user_id"] and item.get("date") == row["date"])
    ]
    filtered.append(row)
    save_table(table_name, filtered)
    return row


def _readiness_label(score: int) -> str:
    if score >= 80:
        return "high"
    if score >= 55:
        return "moderate"
    return "low"


def _recommended_intensity(score: int) -> str:
    if score >= 80:
        return "high"
    if score >= 55:
        return "moderate"
    return "low"


def generate_mock_current_data(
    user_id: str,
    date: str,
    ranges: dict[str, Any] | None = None,
    seed: int | None = None,
) -> dict[str, Any] | None:
    if get_profile_by_user_id(user_id) is None:
        return None

    ranges = ranges or {}
    rng = random.Random(seed if seed is not None else f"{user_id}:{date}")
    energy_level = _range_value(ranges, "energy_level", 4, 8, 1, 10, rng)
    soreness_level = _range_value(ranges, "soreness_level", 1, 6, 1, 10, rng)
    mood_level = _range_value(ranges, "mood_level", 4, 8, 1, 10, rng)
    available_minutes = _range_value(ranges, "available_minutes", 25, 60, 10, 180, rng)
    self_reported_stress = _range_value(ranges, "self_reported_stress", 2, 7, 1, 10, rng)

    mood = "great" if mood_level >= 8 else "okay" if mood_level >= 5 else "low"
    checkin = {
        "checkin_id": f"dc_{user_id}_{date.replace('-', '')}",
        "user_id": user_id,
        "date": date,
        "energy_level": energy_level,
        "soreness_level": soreness_level,
        "mood_level": mood_level,
        "mood": mood,
        "available_minutes": available_minutes,
        "self_reported_stress": self_reported_stress,
        "notes": "Generated mock current-state check-in for workout recommendation demos.",
    }

    summary = _latest_for_user("user_health_summary", user_id) or {}
    body = _latest_for_user("body_metrics", user_id) or {}
    avg_sleep = float(summary.get("avg_sleep_hours", 7.0))
    avg_steps = int(summary.get("avg_daily_steps", 7000))
    resting_bpm = int(body.get("resting_bpm", 65))

    score = 50
    score += (energy_level - 5) * 5
    score -= max(0, soreness_level - 4) * 4
    score -= max(0, self_reported_stress - 5) * 4
    score += 8 if avg_sleep >= 7 else -8 if avg_sleep < 6 else 0
    score += 5 if avg_steps >= 8000 else -5 if avg_steps < 4000 else 0
    score += 4 if resting_bpm <= 65 else -4 if resting_bpm >= 75 else 0
    score = max(1, min(100, score))

    avoid_workout_types = []
    recommended_workout_types = ["Strength", "Cardio", "Yoga"]
    if score < 55 or soreness_level >= 7:
        avoid_workout_types.append("HIIT")
        recommended_workout_types = ["Yoga", "Cardio"]
    elif score >= 80 and energy_level >= 7:
        recommended_workout_types = ["HIIT", "Strength", "Cardio"]

    reason_parts = [
        f"energy {energy_level}/10",
        f"soreness {soreness_level}/10",
        f"stress {self_reported_stress}/10",
        f"average sleep {avg_sleep}h",
    ]
    readiness = {
        "readiness_id": f"fr_{user_id}_{date.replace('-', '')}",
        "user_id": user_id,
        "date": date,
        "readiness_score": score,
        "recovery_level": _readiness_label(score),
        "sleep_signal": "good_sleep" if avg_sleep >= 7 else "low_sleep" if avg_sleep < 6 else "normal",
        "stress_signal": "high_stress" if self_reported_stress >= 7 else "normal",
        "activity_signal": "active_recently" if avg_steps >= 8000 else "low_recent_activity",
        "recommended_intensity": _recommended_intensity(score),
        "avoid_workout_types": avoid_workout_types,
        "recommended_workout_types": recommended_workout_types,
        "reason": "Mock readiness based on " + ", ".join(reason_parts) + ".",
    }

    _upsert_current_row("daily_checkins", checkin)
    _upsert_current_row("fitness_readiness", readiness)
    return {"daily_checkin": checkin, "fitness_readiness": readiness}


def build_agent_for_user(user_id: str):
    if get_profile_by_user_id(user_id) is None:
        raise ValueError(f"Unknown user_id: {user_id}")

    @tool
    def validate_db_name(db_name: str) -> bool:
        """Validate if the provided local_db table name or alias is valid."""

        normalized = normalize_db_name(db_name)
        return normalized in USER_TABLES or normalized in {"all", "exercise_catalog"}

    @tool
    def query_db(db_name: str, query: str) -> Any:
        """Query local_db data for the logged-in user.

        Args:
            db_name: A table or topic alias such as all, profile, body_metrics,
                daily_activity, hourly_activity, sleep_records, workout_sessions,
                exercise_catalog, or user_health_summary.
            query: Natural-language query context. The demo uses it only to help
                the model decide which table to request.
        """

        normalized = normalize_db_name(db_name)
        if normalized in {"user_profiles", "body_metrics", "user_health_summary"}:
            return current_user_context(user_id)
        return query_local_table(normalized, user_id)

    @tool
    def validate_user_profile(profile: dict[str, Any]) -> bool:
        """Validate that a profile contains the required public user fields."""

        required_fields = {
            "user_id",
            "username",
            "name",
            "age",
            "email",
            "weight",
            "height",
            "gender",
        }
        return required_fields.issubset(profile)

    tools = [validate_db_name, query_db, validate_user_profile]
    tools_by_name = {item.name: item for item in tools}
    model_with_tools = model.bind_tools(tools)

    def llm_call(state: MessagesState) -> dict[str, Any]:
        return {
            "messages": [
                model_with_tools.invoke(
                    [
                        SystemMessage(
                            content=(
                                "You are a helpful health and fitness assistant for the "
                                "currently logged-in user only. The logged-in user_id is "
                                f"{user_id}. Use query_db to answer questions about body "
                                "metrics, sleep, daily steps, hourly activity, calories, "
                                "workouts, exercise details, or health summary. Prefer "
                                "db_name='all' when unsure. After a tool returns data, "
                                "answer the user's exact question directly with the relevant "
                                "values. For average or latest questions, prefer the "
                                "health_summary fields such as avg_daily_steps, "
                                "avg_sleep_hours, latest_weight_kg, latest_bmi, "
                                "primary_workout_type, and latest_sleep_quality. Do not "
                                "explain JSON structure, parsing, or code. "
                                "Never reveal password fields or data for any other user."
                            )
                        )
                    ]
                    + state.get("messages", [])
                )
            ],
            "llm_calls": state.get("llm_calls", 0) + 1,
        }

    def tool_node(state: MessagesState) -> dict[str, Any]:
        result = []
        for tool_call in state["messages"][-1].tool_calls:
            selected_tool = tools_by_name[tool_call["name"]]
            observation = selected_tool.invoke(tool_call["args"])
            result.append(
                ToolMessage(
                    content=json.dumps(observation),
                    tool_call_id=tool_call["id"],
                )
            )
        return {"messages": result}

    def should_continue(state: MessagesState) -> Literal["tool_node", END]:
        last_message = state["messages"][-1]
        if last_message.tool_calls:
            return "tool_node"
        return END

    agent_builder = StateGraph(MessagesState)
    agent_builder.add_node("llm_call", llm_call)
    agent_builder.add_node("tool_node", tool_node)
    agent_builder.add_edge(START, "llm_call")
    agent_builder.add_conditional_edges(
        "llm_call",
        should_continue,
        ["tool_node", END],
    )
    agent_builder.add_edge("tool_node", "llm_call")
    return agent_builder.compile()


def _last_message_text(result: dict[str, Any]) -> str:
    for message in reversed(result["messages"]):
        if getattr(message, "type", None) == "ai" and not getattr(message, "tool_calls", None):
            return str(message.content)
    return str(result["messages"][-1].content)


def run_chat_for_user(user_id: str, message: str) -> str:
    agent = build_agent_for_user(user_id)
    result = agent.invoke(
        {
            "messages": [HumanMessage(content=message)],
            "llm_calls": 0,
        }
    )
    return _last_message_text(result)


if __name__ == "__main__":
    demo_user_id = "u_001"
    demo_message = "What is my weight, average sleep, and primary workout type?"
    print(run_chat_for_user(demo_user_id, demo_message))
