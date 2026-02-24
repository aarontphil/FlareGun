/**
 * MeshLink — WebSocket Relay Server
 * 
 * Lightweight relay that simulates "airwaves" between devices on the same WiFi.
 * Each connected device registers its identity. Messages are broadcast to all
 * other connected devices, simulating BLE mesh broadcast behavior.
 * 
 * Usage: node server.js
 * Listens on port 3001 by default.
 */

import { WebSocketServer } from 'ws';
import { networkInterfaces } from 'os';

const PORT = 3001;
const wss = new WebSocketServer({ port: PORT });

// Connected devices: ws -> { identity, joinedAt }
const devices = new Map();

function broadcast(senderWs, data) {
    const payload = JSON.stringify(data);
    for (const [ws] of devices) {
        if (ws !== senderWs && ws.readyState === 1) {
            ws.send(payload);
        }
    }
}

function broadcastAll(data) {
    const payload = JSON.stringify(data);
    for (const [ws] of devices) {
        if (ws.readyState === 1) {
            ws.send(payload);
        }
    }
}

function getPeerList() {
    return Array.from(devices.values()).map(d => ({
        deviceId: d.identity.id,
        name: d.identity.name,
        emoji: d.identity.emoji,
        joinedAt: d.joinedAt,
    }));
}

wss.on('connection', (ws) => {
    console.log(`[Relay] New connection (${wss.clients.size} total)`);

    ws.on('message', (raw) => {
        try {
            const data = JSON.parse(raw.toString());

            switch (data.type) {
                case 'join': {
                    // Register device identity
                    devices.set(ws, {
                        identity: data.identity,
                        joinedAt: Date.now(),
                    });

                    console.log(`[Relay] 📱 ${data.identity.name} (${data.identity.emoji}) joined — ${devices.size} device(s) online`);

                    // Send peer list to the new device
                    ws.send(JSON.stringify({
                        type: 'peers',
                        peers: getPeerList().filter(p => p.deviceId !== data.identity.id),
                    }));

                    // Notify all others about the new peer
                    broadcast(ws, {
                        type: 'peer_joined',
                        peer: {
                            deviceId: data.identity.id,
                            name: data.identity.name,
                            emoji: data.identity.emoji,
                        },
                    });
                    break;
                }

                case 'message': {
                    // Forward mesh message to all other devices
                    const deviceInfo = devices.get(ws);
                    console.log(`[Relay] ✉️  ${deviceInfo?.identity?.name || '?'} → broadcast: "${data.message.text?.slice(0, 40)}..."`);
                    broadcast(ws, {
                        type: 'message',
                        message: data.message,
                    });
                    break;
                }

                default:
                    console.log(`[Relay] Unknown message type: ${data.type}`);
            }
        } catch (err) {
            console.error('[Relay] Parse error:', err.message);
        }
    });

    ws.on('close', () => {
        const deviceInfo = devices.get(ws);
        if (deviceInfo) {
            console.log(`[Relay] 📴 ${deviceInfo.identity.name} left — ${devices.size - 1} device(s) online`);
            broadcast(ws, {
                type: 'peer_left',
                peer: { deviceId: deviceInfo.identity.id },
            });
        }
        devices.delete(ws);
    });

    ws.on('error', (err) => {
        console.error('[Relay] WebSocket error:', err.message);
    });
});

// Print server info
function getLocalIP() {
    const nets = networkInterfaces();
    for (const name of Object.keys(nets)) {
        for (const net of nets[name]) {
            if (net.family === 'IPv4' && !net.internal) {
                return net.address;
            }
        }
    }
    return 'localhost';
}

const localIP = getLocalIP();
console.log('');
console.log('  ╔══════════════════════════════════════════════╗');
console.log('  ║        MeshLink — WebSocket Relay            ║');
console.log('  ╠══════════════════════════════════════════════╣');
console.log(`  ║  Relay:   ws://${localIP}:${PORT}          ║`);
console.log(`  ║  Status:  ✅ Ready for connections           ║`);
console.log('  ╚══════════════════════════════════════════════╝');
console.log('');
console.log('  Devices on same WiFi can now connect.');
console.log('  Waiting for MeshLink clients...');
console.log('');
