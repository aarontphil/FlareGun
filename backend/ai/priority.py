"""
Priority Scorer — Assigns final message priority based on AI analysis and user input.
"""

from typing import Optional

PRIORITY_LEVELS = {
    "low": 1,
    "normal": 2,
    "high": 3,
    "critical": 4,
}

PRIORITY_LABELS = {
    "low": "📋 Low",
    "normal": "📩 Normal",
    "high": "⚠️ High",
    "critical": "🚨 Critical",
}

PRIORITY_COLORS = {
    "low": "#90a4ae",
    "normal": "#6c5ce7",
    "high": "#ff9100",
    "critical": "#ff1744",
}


def score_message_priority(
    ai_analysis: Optional[dict] = None,
    user_priority: str = "normal",
) -> dict:
    """
    Determine the final priority of a message by combining AI analysis
    with the user-set priority.

    Returns:
        dict with keys: priority, score, reason, ttl_boost, label, color
    """
    score = PRIORITY_LEVELS.get(user_priority, 2)
    reason = f"User set: {user_priority}"

    if ai_analysis and ai_analysis.get("is_emergency"):
        urgency = ai_analysis.get("urgency_score", 0)
        ai_score = min(max(urgency // 2 + 1, 1), 4)
        if ai_score > score:
            score = ai_score
            cat = ai_analysis.get("category_label", "emergency")
            reason = f"AI detected: {cat}"

    # Map score back to priority level
    level_map = {1: "low", 2: "normal", 3: "high", 4: "critical"}
    priority = level_map.get(min(score, 4), "normal")

    # TTL boost for higher priorities
    ttl_boost = max(0, (score - 2) * 3)

    return {
        "priority": priority,
        "score": score,
        "reason": reason,
        "ttl_boost": ttl_boost,
        "label": PRIORITY_LABELS.get(priority, "📩 Normal"),
        "color": PRIORITY_COLORS.get(priority, "#6c5ce7"),
    }
