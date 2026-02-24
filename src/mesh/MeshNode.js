/**
 * MeshNode — Represents THIS device's identity in the mesh network.
 * Generates and persists a unique device identity for peer identification.
 */
import { v4 as uuidv4 } from 'uuid';

const DEVICE_STORAGE_KEY = 'meshlink_device_identity';

/**
 * Device identity — who this phone is on the mesh.
 */
export class DeviceIdentity {
    constructor({ id, name, emoji, createdAt } = {}) {
        this.id = id || uuidv4();
        this.name = name || `MeshUser-${this.id.slice(0, 4)}`;
        this.emoji = emoji || this._randomEmoji();
        this.createdAt = createdAt || Date.now();
    }

    _randomEmoji() {
        const emojis = ['🟢', '🔵', '🟣', '🟠', '🔴', '🟡', '⚪', '🧑‍🚀', '🧑‍🚒', '🧑‍⚕️', '🦺', '📡'];
        return emojis[Math.floor(Math.random() * emojis.length)];
    }

    toJSON() {
        return {
            id: this.id,
            name: this.name,
            emoji: this.emoji,
            createdAt: this.createdAt,
        };
    }
}

/**
 * Load or create device identity from localStorage.
 */
export function loadDeviceIdentity() {
    try {
        const stored = localStorage.getItem(DEVICE_STORAGE_KEY);
        if (stored) {
            const data = JSON.parse(stored);
            return new DeviceIdentity(data);
        }
    } catch (e) {
        console.warn('[Identity] Failed to load:', e);
    }

    const identity = new DeviceIdentity();
    saveDeviceIdentity(identity);
    return identity;
}

/**
 * Save device identity to localStorage.
 */
export function saveDeviceIdentity(identity) {
    try {
        localStorage.setItem(DEVICE_STORAGE_KEY, JSON.stringify(identity.toJSON()));
    } catch (e) {
        console.warn('[Identity] Failed to save:', e);
    }
}

/**
 * Update device name.
 */
export function updateDeviceName(identity, newName) {
    identity.name = newName;
    saveDeviceIdentity(identity);
    return identity;
}

/**
 * Update device emoji/avatar.
 */
export function updateDeviceEmoji(identity, newEmoji) {
    identity.emoji = newEmoji;
    saveDeviceIdentity(identity);
    return identity;
}
