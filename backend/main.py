"""
MeshLink — Python Backend Server

FastAPI server providing:
1. WebSocket relay for multi-device mesh communication
2. REST API for AI classification, summarization, and knowledge base
3. Auto-displays local IP for phone access

Usage:
    python main.py
    or: uvicorn main:app --host 0.0.0.0 --port 8000
"""

import json
import socket
import asyncio
from datetime import datetime
from typing import Optional
from uuid import uuid4

from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

from ai.classifier import classify_message, get_category_label, get_urgency_color
from ai.priority import score_message_priority
from ai.summarizer import summarize_message
from ai.knowledge import get_all_categories, get_topic_content, get_ai_response

# ─── App Setup ──────────────────────────────────────────────

app = FastAPI(
    title="MeshLink Relay Server",
    description="Offline mesh communication relay with AI analysis",
    version="2.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


# ─── Data Models ────────────────────────────────────────────

class ClassifyRequest(BaseModel):
    text: str

class SummarizeRequest(BaseModel):
    text: str
    max_sentences: int = 3

class AIQueryRequest(BaseModel):
    query: str

class PriorityRequest(BaseModel):
    text: str
    user_priority: str = "normal"


# ─── WebSocket Relay ────────────────────────────────────────

class ConnectionManager:
    """Manages WebSocket connections for the mesh relay."""

    def __init__(self):
        self.connections: dict[str, dict] = {}  # device_id -> {ws, identity, joined_at}

    async def connect(self, websocket: WebSocket, device_id: str, identity: dict):
        self.connections[device_id] = {
            "ws": websocket,
            "identity": identity,
            "joined_at": datetime.now().isoformat(),
        }
        print(f"[Relay] 📱 {identity.get('name', '?')} ({identity.get('emoji', '📱')}) joined — {len(self.connections)} device(s)")

        # Send peer list to the new device
        peers = self.get_peer_list(exclude=device_id)
        await websocket.send_json({
            "type": "peers",
            "peers": peers,
        })

        # Notify others
        await self.broadcast({
            "type": "peer_joined",
            "peer": {
                "deviceId": device_id,
                "name": identity.get("name", "Unknown"),
                "emoji": identity.get("emoji", "📱"),
            },
        }, exclude=device_id)

    def disconnect(self, device_id: str):
        info = self.connections.pop(device_id, None)
        if info:
            name = info["identity"].get("name", "?")
            print(f"[Relay] 📴 {name} left — {len(self.connections)} device(s)")
        return info

    async def broadcast(self, data: dict, exclude: Optional[str] = None):
        """Broadcast a message to all connected devices except `exclude`."""
        payload = json.dumps(data)
        disconnected = []
        for dev_id, conn in self.connections.items():
            if dev_id == exclude:
                continue
            try:
                await conn["ws"].send_text(payload)
            except Exception:
                disconnected.append(dev_id)
        for dev_id in disconnected:
            self.disconnect(dev_id)

    def get_peer_list(self, exclude: Optional[str] = None) -> list[dict]:
        """Get list of all connected peers."""
        return [
            {
                "deviceId": dev_id,
                "name": conn["identity"].get("name", "Unknown"),
                "emoji": conn["identity"].get("emoji", "📱"),
                "joinedAt": conn["joined_at"],
            }
            for dev_id, conn in self.connections.items()
            if dev_id != exclude
        ]

    @property
    def count(self) -> int:
        return len(self.connections)


manager = ConnectionManager()


@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()
    device_id: Optional[str] = None

    try:
        while True:
            raw = await websocket.receive_text()
            data = json.loads(raw)

            if data["type"] == "join":
                identity = data.get("identity", {})
                device_id = identity.get("id", str(uuid4()))
                await manager.connect(websocket, device_id, identity)

            elif data["type"] == "message":
                message = data.get("message", {})
                sender = manager.connections.get(device_id, {}).get("identity", {})
                name = sender.get("name", "?")
                text = message.get("text", "")
                print(f"[Relay] ✉️  {name} → broadcast: \"{text[:50]}\"")

                # AI-analyze the message on the server side
                classification = classify_message(text)
                priority_result = score_message_priority(classification, message.get("priority", "normal"))
                message["aiAnalysis"] = classification
                message["aiPriority"] = priority_result

                await manager.broadcast(
                    {"type": "message", "message": message},
                    exclude=device_id,
                )

    except WebSocketDisconnect:
        pass
    except Exception as e:
        print(f"[Relay] Error: {e}")
    finally:
        if device_id:
            info = manager.disconnect(device_id)
            if info:
                await manager.broadcast({
                    "type": "peer_left",
                    "peer": {"deviceId": device_id},
                })


# ─── REST Endpoints ─────────────────────────────────────────

@app.get("/")
async def health():
    return {
        "service": "MeshLink Relay",
        "version": "2.0.0",
        "connected_devices": manager.count,
        "peers": manager.get_peer_list(),
    }


@app.post("/ai/classify")
async def ai_classify(req: ClassifyRequest):
    result = classify_message(req.text)
    return result


@app.post("/ai/summarize")
async def ai_summarize(req: SummarizeRequest):
    result = summarize_message(req.text, req.max_sentences)
    return result


@app.post("/ai/priority")
async def ai_priority(req: PriorityRequest):
    classification = classify_message(req.text)
    result = score_message_priority(classification, req.user_priority)
    return {**result, "classification": classification}


@app.post("/ai/chat")
async def ai_chat(req: AIQueryRequest):
    result = get_ai_response(req.query)
    return result


@app.get("/ai/knowledge")
async def ai_knowledge():
    return {"categories": get_all_categories()}


@app.get("/ai/knowledge/{category}/{topic}")
async def ai_knowledge_topic(category: str, topic: str):
    content = get_topic_content(category, topic)
    return {"category": category, "topic": topic, "content": content}


# ─── Startup ────────────────────────────────────────────────

def get_local_ip() -> str:
    """Get the local IP address."""
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except Exception:
        return "localhost"


if __name__ == "__main__":
    import uvicorn

    local_ip = get_local_ip()
    port = 8000

    print()
    print("  ╔══════════════════════════════════════════════════╗")
    print("  ║          MeshLink — Python Relay Server          ║")
    print("  ╠══════════════════════════════════════════════════╣")
    print(f"  ║  HTTP:  http://{local_ip}:{port}               ║")
    print(f"  ║  WS:    ws://{local_ip}:{port}/ws              ║")
    print("  ║  Status: ✅ Ready for connections                ║")
    print("  ╚══════════════════════════════════════════════════╝")
    print()
    print(f"  📱 Open your Flutter app and connect to: {local_ip}:{port}")
    print("  Waiting for MeshLink clients...")
    print()

    uvicorn.run(app, host="0.0.0.0", port=port, log_level="info")
