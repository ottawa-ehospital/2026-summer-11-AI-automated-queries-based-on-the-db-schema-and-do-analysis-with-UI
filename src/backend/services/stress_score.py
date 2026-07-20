from __future__ import annotations

_HRV_BASELINE_MS = 50.0
_RESTING_HR_BASELINE_BPM = 60.0
_RESPIRATORY_BASELINE_BPM = 14.0

_HRV_WEIGHT = 0.5
_RESTING_HR_WEIGHT = 0.3
_RESPIRATORY_WEIGHT = 0.2


def _clamp(value: float, low: float = 0.0, high: float = 100.0) -> float:
    return max(low, min(high, value))


def _hrv_component(hrv_sdnn: float) -> float:
    return _clamp((1.0 - (hrv_sdnn / _HRV_BASELINE_MS)) * 100.0)


def _resting_hr_component(resting_heart_rate: float) -> float:
    return _clamp((resting_heart_rate - _RESTING_HR_BASELINE_BPM) * 2.5)


def _respiratory_component(respiratory_rate: float) -> float:
    return _clamp((respiratory_rate - _RESPIRATORY_BASELINE_BPM) * 8.0)


def compute_stress_score(
    hrv_sdnn: float | None,
    resting_heart_rate: float | None,
    respiratory_rate: float | None,
) -> float | None:
    components: list[tuple[float, float]] = []
    if hrv_sdnn is not None:
        components.append((_HRV_WEIGHT, _hrv_component(hrv_sdnn)))
    if resting_heart_rate is not None:
        components.append((_RESTING_HR_WEIGHT, _resting_hr_component(resting_heart_rate)))
    if respiratory_rate is not None:
        components.append((_RESPIRATORY_WEIGHT, _respiratory_component(respiratory_rate)))

    if not components:
        return None

    total_weight = sum(weight for weight, _ in components)
    weighted = sum(weight * score for weight, score in components)
    return round(_clamp(weighted / total_weight), 2)
