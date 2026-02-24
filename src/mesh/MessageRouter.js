/**
 * MessageRouter — Message creation and relay logic for real BLE mesh.
 * Handles message flooding with deduplication and TTL hop limits.
 */
import { v4 as uuidv4 } from 'uuid';

export const MessagePriority = {
    CRITICAL: 'critical',
    HIGH: 'high',
    NORMAL: 'normal',
    LOW: 'low',
};

const MAX_TTL = 5; // Maximum relay hops

/**
 * Create a new mesh message.
 */
export function createMessage({ text, senderId, senderName, senderEmoji, priority = 'normal', timestamp }) {
    return {
        id: uuidv4(),
        text,
        senderId,
        senderName: senderName || 'Unknown',
        senderEmoji: senderEmoji || '📱',
        priority,
        timestamp: timestamp || Date.now(),
        ttl: MAX_TTL,
        relayCount: 0,
        hops: [],
    };
}

/**
 * Relay an incoming message to all other connected peers (excluding the source).
 * Implements basic flooding with TTL to prevent infinite relay loops.
 */
export function routeMessage(bluetoothManager, message, sourceDeviceId) {
    // Don't relay if TTL exhausted
    if (message.ttl <= 0) return [];

    const relayMessage = {
        ...message,
        ttl: message.ttl - 1,
        hops: [...(message.hops || []), sourceDeviceId],
    };

    const results = [];
    for (const [deviceId] of bluetoothManager.connectedPeers) {
        // Don't relay back to sender or anyone in the hop chain
        if (deviceId === sourceDeviceId || relayMessage.hops.includes(deviceId)) {
            continue;
        }

        bluetoothManager.sendToPeer(deviceId, relayMessage)
            .then(() => results.push({ deviceId, success: true }))
            .catch((err) => results.push({ deviceId, success: false, error: err.message }));
    }

    return results;
}

/**
 * Get priority color for UI display.
 */
export function getPriorityColor(priority) {
    switch (priority) {
        case MessagePriority.CRITICAL: return '#ff1744';
        case MessagePriority.HIGH: return '#ff9100';
        case MessagePriority.NORMAL: return '#6c5ce7';
        case MessagePriority.LOW: return '#90a4ae';
        default: return '#6c5ce7';
    }
}

/**
 * Get priority label.
 */
export function getPriorityLabel(priority) {
    switch (priority) {
        case MessagePriority.CRITICAL: return '🚨 Critical';
        case MessagePriority.HIGH: return '⚠️ High';
        case MessagePriority.NORMAL: return '📩 Normal';
        case MessagePriority.LOW: return '📋 Low';
        default: return '📩 Normal';
    }
}
