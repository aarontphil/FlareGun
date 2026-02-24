/**
 * PeerDiscovery — BLE-based peer discovery for MeshLink.
 * Manages the list of known peers, their status, and connection history.
 */

/**
 * PeerManager — tracks discovered and connected peers.
 */
export class PeerManager {
    constructor() {
        this.peers = new Map(); // deviceId -> PeerInfo
    }

    /**
     * Add or update a peer when discovered/connected via BLE.
     */
    addPeer(deviceId, info) {
        const existing = this.peers.get(deviceId);
        this.peers.set(deviceId, {
            deviceId,
            name: info.name || existing?.name || 'Unknown',
            emoji: info.emoji || existing?.emoji || '📱',
            identity: info.identity || existing?.identity || null,
            connected: info.connected ?? existing?.connected ?? false,
            lastSeen: Date.now(),
            firstSeen: existing?.firstSeen || Date.now(),
            messageCount: existing?.messageCount || 0,
            rssi: info.rssi || null,
        });
    }

    /**
     * Mark a peer as disconnected.
     */
    removePeer(deviceId) {
        const peer = this.peers.get(deviceId);
        if (peer) {
            peer.connected = false;
            peer.lastSeen = Date.now();
        }
    }

    /**
     * Increment message count for a peer.
     */
    recordMessage(deviceId) {
        const peer = this.peers.get(deviceId);
        if (peer) {
            peer.messageCount++;
            peer.lastSeen = Date.now();
        }
    }

    /**
     * Get all known peers.
     */
    getAllPeers() {
        return Array.from(this.peers.values());
    }

    /**
     * Get connected peers only.
     */
    getConnectedPeers() {
        return this.getAllPeers().filter(p => p.connected);
    }

    /**
     * Get peer count.
     */
    getCount() {
        return {
            total: this.peers.size,
            connected: this.getConnectedPeers().length,
        };
    }

    /**
     * Time since last seen, formatted.
     */
    static formatLastSeen(timestamp) {
        const diff = Date.now() - timestamp;
        if (diff < 60000) return 'just now';
        if (diff < 3600000) return `${Math.floor(diff / 60000)}m ago`;
        if (diff < 86400000) return `${Math.floor(diff / 3600000)}h ago`;
        return `${Math.floor(diff / 86400000)}d ago`;
    }
}
