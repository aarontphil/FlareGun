/**
 * MeshNetwork — Real device mesh coordinator for MeshLink.
 * Manages WebSocket relay connections, message routing, and store-and-forward relay.
 * Falls back to BLE when WebSocket is not available.
 */
import { WebSocketTransport, isWebSocketSupported } from './WebSocketTransport.js';
import { BluetoothManager, isBluetoothSupported } from './BluetoothManager.js';
import { PeerManager } from './PeerDiscovery.js';
import { loadDeviceIdentity, saveDeviceIdentity } from './MeshNode.js';
import { createMessage, routeMessage } from './MessageRouter.js';
import { db } from '../storage/Database.js';

export { createMessage, MessagePriority } from './MessageRouter.js';

export class MeshNetwork {
    constructor() {
        // Use WebSocket transport (for multi-device over WiFi)
        this.transport = new WebSocketTransport();
        this.bluetooth = new BluetoothManager();
        this.peerManager = new PeerManager();
        this.identity = loadDeviceIdentity();
        this.messages = [];         // all messages (sent + received)
        this.listeners = new Set();
        this.bluetoothSupported = isBluetoothSupported();
        this.wsConnected = false;

        // Set identity on both transports
        this.transport.setIdentity(this.identity);
        this.bluetooth.setIdentity(this.identity);

        // Listen for WebSocket transport events
        this.transport.subscribe((event, data) => {
            this._handleTransportEvent(event, data);
        });

        // Listen for BLE events as fallback
        this.bluetooth.subscribe((event, data) => {
            this._handleTransportEvent(event, data);
        });

        // Load persisted messages
        this._loadMessages();

        // Auto-connect WebSocket transport
        this.transport.connect();
    }

    /**
     * Get device identity.
     */
    getIdentity() {
        return this.identity;
    }

    /**
     * Update device name.
     */
    setDeviceName(name) {
        this.identity.name = name;
        saveDeviceIdentity(this.identity);
        this.transport.setIdentity(this.identity);
        this.bluetooth.setIdentity(this.identity);
        this._notify();
    }

    /**
     * Scan for nearby peers.
     * Uses WebSocket relay (auto-discovery) or BLE scan.
     */
    async scanForPeers() {
        // Try WebSocket first (peers auto-discovered)
        if (this.transport.isConnected()) {
            return this.transport.scanForPeers();
        }
        // Fallback to BLE
        if (this.bluetoothSupported) {
            return this.bluetooth.scanForPeers();
        }
        throw new Error('No transport available (WebSocket disconnected, Bluetooth not supported)');
    }

    /**
     * Send a message to all connected peers (broadcast).
     */
    async sendMessage(text, priority = 'normal') {
        const message = createMessage({
            text,
            senderId: this.identity.id,
            senderName: this.identity.name,
            senderEmoji: this.identity.emoji,
            priority,
            timestamp: Date.now(),
        });

        // Store locally
        this.messages.push(message);
        await this._persistMessage(message);

        // Broadcast via WebSocket transport (primary)
        if (this.transport.isConnected()) {
            const results = await this.transport.broadcast(message);
            message.relayCount = results.filter(r => r.success).length;
        }
        // Also broadcast via BLE if available
        if (this.bluetooth.connectedPeers.size > 0) {
            const bleResults = await this.bluetooth.broadcast(message);
            message.relayCount = (message.relayCount || 0) + bleResults.filter(r => r.success).length;
        }

        this._notify();
        return message;
    }

    /**
     * Get all messages, sorted by timestamp.
     */
    getMessages() {
        return [...this.messages].sort((a, b) => a.timestamp - b.timestamp);
    }

    /**
     * Get connected peers list (from both transports).
     */
    getConnectedPeers() {
        return this.peerManager.getConnectedPeers();
    }

    /**
     * Get all known peers.
     */
    getAllPeers() {
        return this.peerManager.getAllPeers();
    }

    /**
     * Get network stats.
     */
    getStats() {
        const peerCount = this.peerManager.getCount();
        return {
            deviceId: this.identity.id,
            deviceName: this.identity.name,
            connectedPeers: peerCount.connected,
            totalPeers: peerCount.total,
            totalMessages: this.messages.length,
            bluetoothSupported: this.bluetoothSupported,
            isScanning: this.transport.scanning || this.bluetooth.scanning,
            wsConnected: this.transport.isConnected(),
        };
    }

    /**
     * Disconnect from a specific peer.
     */
    disconnectPeer(deviceId) {
        this.transport.disconnect(deviceId);
        this.bluetooth.disconnect(deviceId);
        this.peerManager.removePeer(deviceId);
        this._notify();
    }

    /**
     * Subscribe to network state changes.
     */
    subscribe(listener) {
        this.listeners.add(listener);
        return () => this.listeners.delete(listener);
    }

    // ─── Private ──────────────────

    _handleTransportEvent(event, data) {
        switch (event) {
            case 'connected':
                this.peerManager.addPeer(data.deviceId, {
                    ...data.identity,
                    connected: true,
                });
                this._notify();
                break;

            case 'disconnected':
                this.peerManager.removePeer(data.deviceId);
                this._notify();
                break;

            case 'messageReceived':
                this._handleIncomingMessage(data.deviceId, data.message);
                break;

            case 'relay_connected':
                this.wsConnected = true;
                this._notify();
                break;

            case 'relay_disconnected':
                this.wsConnected = false;
                this._notify();
                break;

            case 'scanning':
                this._notify();
                break;
        }
    }

    async _handleIncomingMessage(deviceId, message) {
        // Dedup
        if (this.messages.find(m => m.id === message.id)) return;

        // Record
        this.peerManager.recordMessage(deviceId);
        message.receivedAt = Date.now();
        message.relayedBy = deviceId;
        this.messages.push(message);
        await this._persistMessage(message);

        // Relay to other connected BLE peers (store-and-forward mesh)
        if (this.bluetooth.connectedPeers.size > 0) {
            routeMessage(this.bluetooth, message, deviceId);
        }

        this._notify();
    }

    async _persistMessage(message) {
        try {
            await db.messages.put(message);
        } catch (e) {
            console.warn('[MeshNetwork] Failed to persist message:', e);
        }
    }

    async _loadMessages() {
        try {
            const stored = await db.messages.toArray();
            this.messages = stored || [];
            this._notify();
        } catch (e) {
            console.warn('[MeshNetwork] Failed to load messages:', e);
        }
    }

    _notify() {
        for (const listener of this.listeners) {
            try { listener(this); } catch (e) { console.error('[MeshNetwork]', e); }
        }
    }
}
