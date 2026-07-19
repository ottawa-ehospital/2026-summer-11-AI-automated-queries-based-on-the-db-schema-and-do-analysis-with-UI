from __future__ import annotations

from src.backend.schemas.nutrition_monitor import PersonalizedInsights


SCORE_HIGH_RISK = -10
SCORE_WARNING = -3
SCORE_POSITIVE = 2


def calculate_health_score(insights: PersonalizedInsights) -> int:
    score = 0
    has_real_insights = False
    if insights.risks:
        score += len(insights.risks) * SCORE_HIGH_RISK
        has_real_insights = True
    if insights.warnings:
        score += len(insights.warnings) * SCORE_WARNING
        has_real_insights = True
    positives = [item for item in insights.positives if not item.startswith("NEUTRAL:")]
    if positives:
        score += len(positives) * SCORE_POSITIVE
        has_real_insights = True
    if score == 0 and has_real_insights:
        return -1
    return score


def final_verdict(insights: PersonalizedInsights) -> tuple[str, str]:
    if insights.risks:
        return (
            "not_recommended",
            "The high risks associated with this meal strongly outweigh any potential benefits.",
        )
    score = calculate_health_score(insights)
    if score < 0:
        return (
            "consume_in_moderation",
            "This meal has drawbacks that may conflict with the current health profile.",
        )
    if score == 0:
        return (
            "neutral_choice",
            "This meal has no immediate risks for the current health profile.",
        )
    return (
        "recommended",
        "This meal appears to align well with the current health profile and goals.",
    )


def ensure_neutral_positive(insights: PersonalizedInsights) -> PersonalizedInsights:
    if not insights.risks and not insights.warnings and not insights.positives:
        insights.positives.append(
            "NEUTRAL: This food poses no immediate risks or warnings for your health profile."
        )
    return insights


def apply_exact_allergy_risks(
    *,
    dish_name: str,
    ingredients: list[str],
    allergy_terms: list[str],
    insights: PersonalizedInsights,
) -> PersonalizedInsights:
    detected = {_normalize(dish_name), *{_normalize(item) for item in ingredients}}
    existing = {_normalize(item) for item in insights.risks}
    for allergen in allergy_terms:
        normalized = _normalize(allergen)
        if not normalized or normalized not in detected:
            continue
        risk = f"HIGH RISK: Contains {allergen}, which is on your allergy list."
        if _normalize(risk) not in existing:
            insights.risks.append(risk)
            existing.add(_normalize(risk))
    return insights


def _normalize(value: str) -> str:
    return " ".join(value.strip().lower().split())
