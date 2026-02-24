import Dexie from 'dexie';

/**
 * Database — Offline-first persistence using Dexie.js (IndexedDB wrapper).
 * Stores messages, peers, keys, AI conversations, and settings locally.
 */

export const db = new Dexie('MeshLinkDB');

db.version(2).stores({
    messages: 'id, senderId, timestamp, priority',
    peers: 'deviceId, name, lastSeen',
    keys: 'deviceId',
    aiConversations: '++id, timestamp',
    emergencyContacts: '++id, name',
    settings: 'key',
});

/** Save a message */
export async function saveMessage(message) {
    return db.messages.put(message);
}

/** Get all messages sorted by timestamp */
export async function getAllMessages() {
    return db.messages.orderBy('timestamp').toArray();
}

/** Save peer info */
export async function savePeer(peer) {
    return db.peers.put(peer);
}

/** Get all peers */
export async function getAllPeers() {
    return db.peers.toArray();
}

/** Save AI conversation entry */
export async function saveAIConversation(entry) {
    return db.aiConversations.put(entry);
}

/** Get AI conversation history */
export async function getAIHistory() {
    return db.aiConversations.orderBy('timestamp').toArray();
}

/** Save a setting */
export async function saveSetting(key, value) {
    return db.settings.put({ key, value });
}

/** Get a setting */
export async function getSetting(key) {
    const result = await db.settings.get(key);
    return result ? result.value : null;
}

/** Save key material */
export async function saveKeyMaterial(deviceId, publicKeyJwk) {
    return db.keys.put({ deviceId, publicKeyJwk });
}

/** Get key material */
export async function getKeyMaterial(deviceId) {
    return db.keys.get(deviceId);
}

/** Clear all data */
export async function clearAllData() {
    await Promise.all([
        db.messages.clear(),
        db.peers.clear(),
        db.keys.clear(),
        db.aiConversations.clear(),
        db.settings.clear(),
    ]);
}

/** Get stats */
export async function getMessageStats() {
    const messages = await db.messages.toArray();
    return {
        total: messages.length,
        emergency: messages.filter(m => m.priority === 'critical' || m.priority === 'high').length,
    };
}

export default db;
