/**
 * WebSocketTransport — Drop-in network transport for MeshLink.
 * Connects to the WebSocket relay server on the local network.
 * Same event interface as BluetoothManager so MeshNetwork works unchanged.
 */

const RECONNECT_DELAY = 3000; // ms

export class WebSocketTransport {
    constructor() {
        this.ws = null;
        this.connectedPeers = new Map(); // deviceId -> { identity, joinedAt }
        this.listeners = new Set();
        this.scanning = false;
        this.myIdentity = null;
        this.connected = false;
        this._reconnectTimer = null;
        this._relayUrl = null;
    }

    /**
     * Set this device's identity.
     */
    setIdentity(identity) {
        this.myIdentity = identity;
        // If already connected, re-announce
        if (this.ws && this.ws.readyState === 1) {
            this._sendJoin();
        }
    }

    /**
     * Connect to the WebSocket relay server.
     * Auto-detects the relay URL based on the current page host.
     */
    connect(relayUrl) {
        this._relayUrl = relayUrl || this._getRelayUrl();
        this._doConnect();
    }

    /**
     * Scan for peers — in WebSocket mode, just request the peer list.
     * Peers are auto-discovered, so this is mostly a no-op.
     */
    async scanForPeers() {
        this.scanning = true;
        this._notify('scanning', { scanning: true });

        // Peers are already auto-discovered via relay
        // Just trigger a re-announce to get fresh peer list
        if (this.ws && this.ws.readyState === 1) {
            this._sendJoin();
        }

        setTimeout(() => {
            this.scanning = false;
            this._notify('scanning', { scanning: false });
        }, 1000);

        return null;
    }

    /**
     * Broadcast a message to all connected peers via the relay.
     */
    async broadcast(message) {
        if (!this.ws || this.ws.readyState !== 1) {
            return [{ deviceId: 'relay', success: false, error: 'Not connected to relay' }];
        }

        this.ws.send(JSON.stringify({
            type: 'message',
            message,
        }));

        // Return success for all known peers
        const results = [];
        for (const [deviceId] of this.connectedPeers) {
            results.push({ deviceId, success: true });
        }
        return results;
    }

    /**
     * Send a message to a specific peer (via relay broadcast).
     * In relay mode, all messages go through the relay anyway.
     */
    async sendToPeer(deviceId, message) {
        return this.broadcast(message);
    }

    /**
     * Disconnect from a peer (remove from local tracking).
     */
    disconnect(deviceId) {
        this.connectedPeers.delete(deviceId);
        this._notify('disconnected', { deviceId });
    }

    /**
     * Disconnect from the relay entirely.
     */
    disconnectAll() {
        if (this._reconnectTimer) {
            clearTimeout(this._reconnectTimer);
            this._reconnectTimer = null;
        }
        if (this.ws) {
            this.ws.close();
            this.ws = null;
        }
        this.connectedPeers.clear();
        this.connected = false;
    }

    /**
     * Get list of connected peers.
     */
    getConnectedPeers() {
        return Array.from(this.connectedPeers.entries()).map(([id, peer]) => ({
            deviceId: id,
            name: peer.name || peer.identity?.name || 'Unknown',
            identity: peer.identity || peer,
            connectedAt: peer.joinedAt,
        }));
    }

    /**
     * Subscribe to transport events.
     */
    subscribe(listener) {
        this.listeners.add(listener);
        return () => this.listeners.delete(listener);
    }

    /**
     * Check if connected to relay.
     */
    isConnected() {
        return this.ws && this.ws.readyState === 1;
    }

    // ─── Private ──────────────────

    _getRelayUrl() {
        // Use the same host as the page but on port 3001
        const host = window.location.hostname || 'localhost';
        return `ws://${host}:3001`;
    }

    _doConnect() {
        if (this.ws && (this.ws.readyState === 0 || this.ws.readyState === 1)) {
            return; // Already connecting or connected
        }

        try {
            console.log(`[WS] Connecting to relay: ${this._relayUrl}`);
            this.ws = new WebSocket(this._relayUrl);

            this.ws.onopen = () => {
                console.log('[WS] ✅ Connected to relay');
                this.connected = true;
                this._sendJoin();
                this._notify('relay_connected', {});
            };

            this.ws.onmessage = (event) => {
                this._handleMessage(event.data);
            };

            this.ws.onclose = () => {
                console.log('[WS] Disconnected from relay');
                this.connected = false;
                // Mark all peers as disconnected
                for (const [deviceId] of this.connectedPeers) {
                    this._notify('disconnected', { deviceId });
                }
                this.connectedPeers.clear();
                this._notify('relay_disconnected', {});
                // Auto-reconnect
                this._scheduleReconnect();
            };

            this.ws.onerror = (err) => {
                console.warn('[WS] Connection error');
                // onclose will fire after this
            };
        } catch (err) {
            console.error('[WS] Failed to create WebSocket:', err);
            this._scheduleReconnect();
        }
    }

    _scheduleReconnect() {
        if (this._reconnectTimer) return;
        this._reconnectTimer = setTimeout(() => {
            this._reconnectTimer = null;
            console.log('[WS] Attempting reconnect...');
            this._doConnect();
        }, RECONNECT_DELAY);
    }

    _sendJoin() {
        if (!this.myIdentity || !this.ws || this.ws.readyState !== 1) return;
        this.ws.send(JSON.stringify({
            type: 'join',
            identity: {
                id: this.myIdentity.id,
                name: this.myIdentity.name,
                emoji: this.myIdentity.emoji,
            },
        }));
    }

    _handleMessage(raw) {
        try {
            const data = JSON.parse(raw);

            switch (data.type) {
                case 'peers': {
                    // Full peer list from relay
                    for (const peer of data.peers) {
                        if (peer.deviceId === this.myIdentity?.id) continue;
                        this.connectedPeers.set(peer.deviceId, {
                            identity: peer,
                            name: peer.name,
                            emoji: peer.emoji,
                            joinedAt: peer.joinedAt,
                        });
                        this._notify('connected', {
                            deviceId: peer.deviceId,
                            identity: peer,
                        });
                    }
                    break;
                }

                case 'peer_joined': {
                    const peer = data.peer;
                    if (peer.deviceId === this.myIdentity?.id) break;
                    this.connectedPeers.set(peer.deviceId, {
                        identity: peer,
                        name: peer.name,
                        emoji: peer.emoji,
                        joinedAt: Date.now(),
                    });
                    this._notify('connected', {
                        deviceId: peer.deviceId,
                        identity: peer,
                    });
                    console.log(`[WS] 📱 Peer joined: ${peer.name}`);
                    break;
                }

                case 'peer_left': {
                    const { deviceId } = data.peer;
                    this.connectedPeers.delete(deviceId);
                    this._notify('disconnected', { deviceId });
                    console.log(`[WS] 📴 Peer left: ${deviceId}`);
                    break;
                }

                case 'message': {
                    // Incoming mesh message from another device
                    this._notify('messageReceived', {
                        deviceId: data.message.senderId,
                        message: data.message,
                    });
                    break;
                }
            }
        } catch (err) {
            console.warn('[WS] Failed to parse message:', err);
        }
    }

    _notify(event, data) {
        for (const listener of this.listeners) {
            try {
                listener(event, data);
            } catch (e) {
                console.error('[WS] Listener error:', e);
            }
        }
    }
}

/**
 * Check if WebSocket transport is available (always true in browsers).
 */
export function isWebSocketSupported() {
    return typeof WebSocket !== 'undefined';
}
