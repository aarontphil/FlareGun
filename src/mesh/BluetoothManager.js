/**
 * BluetoothManager — Web Bluetooth API wrapper for MeshLink.
 * Handles BLE device scanning, GATT connections, and data transfer.
 * Uses a custom MeshLink Service UUID for peer discovery.
 */

// MeshLink custom BLE UUIDs
const MESHLINK_SERVICE_UUID = '0000ff01-0000-1000-8000-00805f9b34fb';
const MESHLINK_MSG_CHAR_UUID = '0000ff02-0000-1000-8000-00805f9b34fb';
const MESHLINK_IDENTITY_CHAR_UUID = '0000ff03-0000-1000-8000-00805f9b34fb';

// BLE MTU limit (conservative)
const MAX_CHUNK_SIZE = 512;

/**
 * Check if Web Bluetooth is available on this device.
 */
export function isBluetoothSupported() {
    return !!(navigator.bluetooth && navigator.bluetooth.requestDevice);
}

/**
 * BluetoothManager — manages BLE connections and message transfer.
 */
export class BluetoothManager {
    constructor() {
        this.connectedPeers = new Map(); // deviceId -> { device, server, characteristic, identity }
        this.listeners = new Set();
        this.scanning = false;
        this.myIdentity = null;
    }

    /**
     * Set this device's identity (sent to peers on connect).
     */
    setIdentity(identity) {
        this.myIdentity = identity;
    }

    /**
     * Scan for nearby MeshLink devices.
     * Uses navigator.bluetooth.requestDevice which shows the browser's device picker.
     * Returns the selected device or null.
     */
    async scanForPeers() {
        if (!isBluetoothSupported()) {
            throw new Error('Web Bluetooth is not supported on this device/browser');
        }

        this.scanning = true;
        this._notify('scanning', { scanning: true });

        try {
            const device = await navigator.bluetooth.requestDevice({
                filters: [{ services: [MESHLINK_SERVICE_UUID] }],
                optionalServices: [MESHLINK_SERVICE_UUID],
            });

            if (device) {
                await this.connectToDevice(device);
                return device;
            }
            return null;
        } catch (err) {
            if (err.name === 'NotFoundError') {
                // User cancelled the picker
                console.log('[BLE] Scan cancelled by user');
                return null;
            }
            throw err;
        } finally {
            this.scanning = false;
            this._notify('scanning', { scanning: false });
        }
    }

    /**
     * Connect to a discovered BLE device.
     */
    async connectToDevice(device) {
        try {
            console.log(`[BLE] Connecting to ${device.name || device.id}...`);

            // Listen for disconnection
            device.addEventListener('gattserverdisconnected', () => {
                console.log(`[BLE] Device disconnected: ${device.id}`);
                this.connectedPeers.delete(device.id);
                this._notify('disconnected', { deviceId: device.id });
            });

            const server = await device.gatt.connect();
            const service = await server.getPrimaryService(MESHLINK_SERVICE_UUID);

            // Get message characteristic
            let msgCharacteristic = null;
            try {
                msgCharacteristic = await service.getCharacteristic(MESHLINK_MSG_CHAR_UUID);

                // Subscribe to incoming messages
                await msgCharacteristic.startNotifications();
                msgCharacteristic.addEventListener('characteristicvaluechanged', (event) => {
                    this._handleIncomingData(device.id, event.target.value);
                });
            } catch (e) {
                console.warn('[BLE] Message characteristic not available:', e.message);
            }

            // Get peer identity
            let peerIdentity = { name: device.name || 'Unknown', id: device.id };
            try {
                const identityChar = await service.getCharacteristic(MESHLINK_IDENTITY_CHAR_UUID);
                const identityValue = await identityChar.readValue();
                const decoder = new TextDecoder();
                peerIdentity = JSON.parse(decoder.decode(identityValue));
            } catch (e) {
                console.warn('[BLE] Could not read peer identity:', e.message);
            }

            // Store connection
            this.connectedPeers.set(device.id, {
                device,
                server,
                characteristic: msgCharacteristic,
                identity: peerIdentity,
                connectedAt: Date.now(),
                rssi: null,
            });

            this._notify('connected', { deviceId: device.id, identity: peerIdentity });
            console.log(`[BLE] Connected to ${peerIdentity.name}`);
            return peerIdentity;

        } catch (err) {
            console.error(`[BLE] Connection failed:`, err);
            throw err;
        }
    }

    /**
     * Send a message to a specific connected peer.
     */
    async sendToPeer(deviceId, message) {
        const peer = this.connectedPeers.get(deviceId);
        if (!peer || !peer.characteristic) {
            throw new Error(`Peer ${deviceId} not connected or no write characteristic`);
        }

        const encoder = new TextEncoder();
        const data = encoder.encode(JSON.stringify(message));

        // Chunk data for BLE MTU
        const chunks = this._chunkData(data);
        for (const chunk of chunks) {
            await peer.characteristic.writeValue(chunk);
        }

        this._notify('messageSent', { deviceId, messageId: message.id });
    }

    /**
     * Broadcast a message to all connected peers.
     */
    async broadcast(message) {
        const results = [];
        for (const [deviceId] of this.connectedPeers) {
            try {
                await this.sendToPeer(deviceId, message);
                results.push({ deviceId, success: true });
            } catch (err) {
                results.push({ deviceId, success: false, error: err.message });
            }
        }
        return results;
    }

    /**
     * Disconnect from a specific peer.
     */
    disconnect(deviceId) {
        const peer = this.connectedPeers.get(deviceId);
        if (peer && peer.device.gatt.connected) {
            peer.device.gatt.disconnect();
        }
        this.connectedPeers.delete(deviceId);
        this._notify('disconnected', { deviceId });
    }

    /**
     * Disconnect from all peers.
     */
    disconnectAll() {
        for (const [deviceId] of this.connectedPeers) {
            this.disconnect(deviceId);
        }
    }

    /**
     * Get list of connected peers.
     */
    getConnectedPeers() {
        return Array.from(this.connectedPeers.entries()).map(([id, peer]) => ({
            deviceId: id,
            name: peer.identity.name,
            identity: peer.identity,
            connectedAt: peer.connectedAt,
        }));
    }

    /**
     * Subscribe to BLE events.
     */
    subscribe(listener) {
        this.listeners.add(listener);
        return () => this.listeners.delete(listener);
    }

    // ─── Private Methods ──────────────────

    /**
     * Handle incoming data from a BLE characteristic notification.
     */
    _handleIncomingData(deviceId, dataView) {
        try {
            const decoder = new TextDecoder();
            const jsonStr = decoder.decode(dataView.buffer);
            const message = JSON.parse(jsonStr);
            this._notify('messageReceived', { deviceId, message });
        } catch (err) {
            console.warn('[BLE] Failed to parse incoming data:', err);
        }
    }

    /**
     * Chunk data for BLE MTU limits.
     */
    _chunkData(data) {
        const chunks = [];
        for (let i = 0; i < data.length; i += MAX_CHUNK_SIZE) {
            chunks.push(data.slice(i, i + MAX_CHUNK_SIZE));
        }
        return chunks;
    }

    /**
     * Notify all event listeners.
     */
    _notify(event, data) {
        for (const listener of this.listeners) {
            try {
                listener(event, data);
            } catch (e) {
                console.error('[BLE] Listener error:', e);
            }
        }
    }
}
