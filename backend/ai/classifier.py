"""
Emergency Message Classifier — Lightweight NLP for disaster detection.
Uses weighted keyword matching across multiple disaster categories.
"""

import re
from typing import Optional

# Emergency keyword patterns with weights
EMERGENCY_PATTERNS: dict[str, dict] = {
    "immediate_danger": {
        "weight": 1.0,
        "keywords": [
            "sos", "help", "emergency", "danger", "attack", "shooter",
            "bomb", "threat", "hostage", "kidnap", "assault", "weapon",
            "gun", "knife", "die", "dying", "kill", "murder", "rescue",
            "save me", "save us", "trapped", "stuck", "cant move",
        ],
    },
    "natural_disaster": {
        "weight": 0.9,
        "keywords": [
            "earthquake", "tsunami", "hurricane", "tornado", "cyclone",
            "flood", "flooding", "landslide", "avalanche", "volcano",
            "eruption", "storm", "typhoon", "wildfire", "drought",
        ],
    },
    "medical": {
        "weight": 0.85,
        "keywords": [
            "injured", "injury", "bleeding", "broken", "fracture",
            "unconscious", "breathing", "heart attack", "stroke",
            "seizure", "allergic", "poison", "overdose", "cpr",
            "ambulance", "hospital", "doctor", "medical", "wound",
            "burn", "burns", "choking", "pain", "chest pain",
        ],
    },
    "fire": {
        "weight": 0.85,
        "keywords": [
            "fire", "burning", "smoke", "flames", "explosion",
            "exploded", "blast", "gas leak", "chemical", "hazmat",
            "toxic", "fumes", "evacuate", "evacuation",
        ],
    },
    "structural": {
        "weight": 0.8,
        "keywords": [
            "collapse", "collapsed", "building", "bridge", "roof",
            "debris", "rubble", "cave in", "sinkhole", "crack",
            "unstable", "falling", "wreckage",
        ],
    },
    "water": {
        "weight": 0.8,
        "keywords": [
            "drowning", "sinking", "stranded", "water rising",
            "swept away", "shipwreck", "overboard", "raft",
            "life jacket", "coast guard",
        ],
    },
    "missing_persons": {
        "weight": 0.7,
        "keywords": [
            "missing", "lost", "separated", "cant find", "where is",
            "looking for", "last seen", "search party", "locate",
        ],
    },
    "infrastructure": {
        "weight": 0.6,
        "keywords": [
            "power outage", "blackout", "no electricity", "no water",
            "road blocked", "road closed", "bridge out", "no signal",
            "communication down", "supply", "shortage", "ration",
        ],
    },
}

# Urgency amplifiers
URGENCY_AMPLIFIERS: list[dict] = [
    {"pattern": r"!!+", "boost": 0.3},
    {"pattern": r"HELP", "boost": 0.3},
    {"pattern": r"URGENT", "boost": 0.4},
    {"pattern": r"EMERGENCY", "boost": 0.4},
    {"pattern": r"NOW|RIGHT NOW|IMMEDIATELY", "boost": 0.3},
    {"pattern": r"PLEASE|PLS", "boost": 0.1},
    {"pattern": r"\b\d+\s*(people|persons|victims|injured|dead|trapped)\b", "boost": 0.3},
    {"pattern": r"children|kids|baby|elderly|pregnant", "boost": 0.2},
]

# Category labels for display
CATEGORY_LABELS: dict[str, str] = {
    "immediate_danger": "🚨 Immediate Danger",
    "natural_disaster": "🌊 Natural Disaster",
    "medical": "🏥 Medical Emergency",
    "fire": "🔥 Fire / Explosion",
    "structural": "🏗️ Structural Collapse",
    "water": "🌊 Water Emergency",
    "missing_persons": "🔍 Missing Persons",
    "infrastructure": "⚡ Infrastructure Failure",
}

# Urgency colors
URGENCY_COLORS: list[str] = [
    "#90a4ae",  # 0-1
    "#66bb6a",  # 2
    "#66bb6a",  # 3
    "#ffee58",  # 4
    "#ffca28",  # 5
    "#ffa726",  # 6
    "#ff7043",  # 7
    "#ef5350",  # 8
    "#e53935",  # 9
    "#ff1744",  # 10
]


def classify_message(text: str) -> dict:
    """
    Classify a message for emergency content.

    Returns:
        dict with keys: is_emergency, confidence, category, urgency_score,
                       categories, details
    """
    if not text or not text.strip():
        return {
            "is_emergency": False,
            "confidence": 0.0,
            "category": None,
            "urgency_score": 0,
            "categories": [],
            "details": [],
        }

    text_lower = text.lower()
    details: list[dict] = []
    max_score = 0.0
    top_category: Optional[str] = None

    for category, data in EMERGENCY_PATTERNS.items():
        weight = data["weight"]
        matches = []
        for keyword in data["keywords"]:
            if keyword in text_lower:
                matches.append(keyword)

        if matches:
            score = min(len(matches) / 3.0, 1.0) * weight
            details.append({
                "category": category,
                "label": CATEGORY_LABELS.get(category, category),
                "score": round(score, 3),
                "matches": matches,
            })
            if score > max_score:
                max_score = score
                top_category = category

    # Apply urgency amplifiers
    urgency_boost = 0.0
    for amp in URGENCY_AMPLIFIERS:
        if re.search(amp["pattern"], text, re.IGNORECASE):
            urgency_boost += amp["boost"]

    confidence = min((max_score + urgency_boost) * 100, 100.0)
    urgency_score = min(round(max_score * 8 + urgency_boost * 5), 10)
    is_emergency = confidence >= 30.0

    # Sort details by score descending
    details.sort(key=lambda d: d["score"], reverse=True)

    return {
        "is_emergency": is_emergency,
        "confidence": round(confidence, 1),
        "category": top_category,
        "category_label": CATEGORY_LABELS.get(top_category, "") if top_category else "",
        "urgency_score": urgency_score,
        "categories": [d["category"] for d in details],
        "details": details,
    }


def get_category_label(category: Optional[str]) -> str:
    """Get human-readable label for a category."""
    return CATEGORY_LABELS.get(category, "Unknown") if category else "Safe"


def get_urgency_color(score: int) -> str:
    """Get color for urgency score (0-10)."""
    idx = max(0, min(score, len(URGENCY_COLORS) - 1))
    return URGENCY_COLORS[idx]
