"""
Disaster Knowledge Base — Offline reference data for AI assistant.
Provides survival guidance across disaster categories.
"""

KNOWLEDGE_BASE = {
    "earthquake": {
        "label": "🌍 Earthquake",
        "topics": {
            "during": {
                "title": "During an Earthquake",
                "content": (
                    "**Drop, Cover, and Hold On.**\n\n"
                    "• Drop to your hands and knees\n"
                    "• Take Cover under a sturdy desk or table\n"
                    "• Hold On until the shaking stops\n"
                    "• Stay away from windows and heavy furniture\n"
                    "• If outdoors, move to an open area away from buildings\n"
                    "• Do NOT run outside during shaking\n"
                    "• Do NOT stand in doorways (a myth)"
                ),
            },
            "after": {
                "title": "After an Earthquake",
                "content": (
                    "**Check for injuries and hazards.**\n\n"
                    "• Check yourself and others for injuries\n"
                    "• Expect aftershocks — they can be strong\n"
                    "• Check for gas leaks, fire, and structural damage\n"
                    "• Do NOT use elevators\n"
                    "• If trapped, tap on pipes or walls (don't shout — conserve energy)\n"
                    "• Use text messages instead of calls to keep lines open"
                ),
            },
        },
    },
    "flood": {
        "label": "🌊 Flood",
        "topics": {
            "safety": {
                "title": "Flood Safety",
                "content": (
                    "**Move to higher ground immediately.**\n\n"
                    "• Never walk, swim, or drive through flood waters\n"
                    "• 6 inches of moving water can knock you down\n"
                    "• 12 inches of water can carry away a vehicle\n"
                    "• Stay off bridges over fast-moving water\n"
                    "• If trapped in a building, go to the highest floor\n"
                    "• Signal for help from a window or roof"
                ),
            },
            "water": {
                "title": "Safe Drinking Water",
                "content": (
                    "**Assume all water is contaminated after a flood.**\n\n"
                    "• Boil water for at least 1 minute before drinking\n"
                    "• Use water purification tablets if available\n"
                    "• Collect rainwater in clean containers\n"
                    "• Avoid flood water — it contains sewage and chemicals"
                ),
            },
        },
    },
    "fire": {
        "label": "🔥 Fire",
        "topics": {
            "escape": {
                "title": "Fire Escape",
                "content": (
                    "**Get out, stay out, call for help.**\n\n"
                    "• Crawl low under smoke — air is cleaner near the floor\n"
                    "• Feel doors before opening — if hot, use another exit\n"
                    "• Close doors behind you to slow the fire\n"
                    "• If clothes catch fire: Stop, Drop, and Roll\n"
                    "• Never go back into a burning building\n"
                    "• Meet at a pre-designated meeting point"
                ),
            },
        },
    },
    "medical": {
        "label": "🏥 Medical",
        "topics": {
            "first_aid": {
                "title": "Basic First Aid",
                "content": (
                    "**ABCs: Airway, Breathing, Circulation.**\n\n"
                    "• Clear the airway — tilt head back, lift chin\n"
                    "• Check for breathing — look, listen, feel\n"
                    "• Control bleeding — apply direct pressure with clean cloth\n"
                    "• Treat for shock — lay person flat, elevate legs\n"
                    "• Keep injured person warm and calm\n"
                    "• Do NOT move someone with potential spinal injury"
                ),
            },
            "cpr": {
                "title": "CPR Guide",
                "content": (
                    "**Hands-Only CPR for adults.**\n\n"
                    "• Place heel of hand on center of chest\n"
                    "• Push hard and fast — 2 inches deep, 100-120 compressions/min\n"
                    "• Don't stop until help arrives\n"
                    "• Push to the beat of 'Stayin' Alive'\n"
                    "• For children: use one hand; for infants: use two fingers"
                ),
            },
        },
    },
    "shelter": {
        "label": "🏕️ Shelter",
        "topics": {
            "building": {
                "title": "Emergency Shelter",
                "content": (
                    "**Priority: protection from elements.**\n\n"
                    "• Find or create wind protection first\n"
                    "• Use any available materials: tarps, branches, debris\n"
                    "• Insulate from the ground — use leaves, cardboard\n"
                    "• Keep shelter small to retain body heat\n"
                    "• Signal location with bright materials on roof"
                ),
            },
        },
    },
    "communication": {
        "label": "📡 Communication",
        "topics": {
            "offline": {
                "title": "Communication When Offline",
                "content": (
                    "**Use MeshLink for peer-to-peer messaging.**\n\n"
                    "• Bluetooth mesh works without internet or cell towers\n"
                    "• Each connected device extends the network range\n"
                    "• Use CRITICAL priority for emergency messages\n"
                    "• Keep messages short and clear\n"
                    "• Include your location and number of people\n"
                    "• Use SOS if in immediate danger"
                ),
            },
        },
    },
}


def get_all_categories() -> list[dict]:
    """Get all knowledge base categories with their topics."""
    result = []
    for key, cat in KNOWLEDGE_BASE.items():
        topics = []
        for tkey, topic in cat["topics"].items():
            topics.append({
                "key": tkey,
                "title": topic["title"],
            })
        result.append({
            "key": key,
            "label": cat["label"],
            "topics": topics,
        })
    return result


def get_topic_content(category: str, topic: str) -> str:
    """Get content for a specific topic."""
    cat = KNOWLEDGE_BASE.get(category)
    if not cat:
        return "Category not found."
    t = cat["topics"].get(topic)
    if not t:
        return "Topic not found."
    return t["content"]


def search_knowledge(query: str) -> list[dict]:
    """Simple keyword search across the knowledge base."""
    query_lower = query.lower()
    results = []
    for cat_key, cat in KNOWLEDGE_BASE.items():
        for topic_key, topic in cat["topics"].items():
            if (query_lower in topic["title"].lower() or
                    query_lower in topic["content"].lower() or
                    query_lower in cat_key):
                results.append({
                    "category": cat_key,
                    "category_label": cat["label"],
                    "topic_key": topic_key,
                    "title": topic["title"],
                    "content": topic["content"],
                })
    return results


def get_ai_response(query: str) -> dict:
    """
    Simple AI assistant response based on keyword matching against
    the disaster knowledge base.
    """
    query_lower = query.lower()

    # Greeting
    greetings = ["hello", "hi", "hey", "help", "start"]
    if any(g in query_lower for g in greetings):
        return {
            "type": "greeting",
            "text": (
                "👋 **Hello! I'm your MeshLink AI Assistant.**\n\n"
                "I can help with:\n"
                "• 🌍 Earthquake safety\n"
                "• 🌊 Flood survival\n"
                "• 🔥 Fire escape\n"
                "• 🏥 First aid & CPR\n"
                "• 🏕️ Emergency shelter\n"
                "• 📡 Offline communication tips\n\n"
                "Ask me anything about disaster preparedness!"
            ),
        }

    # SOS
    if any(w in query_lower for w in ["sos", "emergency", "danger", "trapped"]):
        return {
            "type": "emergency",
            "text": (
                "🚨 **EMERGENCY DETECTED**\n\n"
                "**Immediate steps:**\n"
                "• Stay calm and assess your surroundings\n"
                "• Use the Chat tab to broadcast an SOS with CRITICAL priority\n"
                "• Include your location and number of people\n"
                "• If trapped: tap on walls/pipes to signal rescuers\n"
                "• Conserve phone battery — reduce brightness\n"
                "• Do NOT move if you suspect spinal injury"
            ),
        }

    # Search knowledge base
    results = search_knowledge(query)
    if results:
        best = results[0]
        return {
            "type": "knowledge",
            "text": f"**{best['title']}**\n\n{best['content']}",
            "data": {"category": best["category"], "topic": best["topic_key"]},
        }

    # Default
    return {
        "type": "general",
        "text": (
            "I don't have specific info on that topic yet. "
            "Try asking about:\n"
            "• Earthquake, flood, or fire safety\n"
            "• First aid or CPR\n"
            "• Emergency shelter building\n"
            "• How to use MeshLink offline"
        ),
    }
