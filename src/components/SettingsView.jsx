import React, { useState } from 'react';
import { updateDeviceName, updateDeviceEmoji, saveDeviceIdentity } from '../mesh/MeshNode.js';
import { clearAllData } from '../storage/Database.js';

const AVATAR_OPTIONS = ['🧑‍🚀', '🧑‍🚒', '🧑‍⚕️', '🦺', '📡', '🟢', '🔵', '🟣', '🟠', '🔴', '🟡', '⚪', '🎯', '💎', '⚡', '🔥'];

export default function SettingsView({ network }) {
    const identity = network.getIdentity();
    const stats = network.getStats();
    const [name, setName] = useState(identity.name);
    const [showAvatars, setShowAvatars] = useState(false);
    const [saved, setSaved] = useState(false);

    const handleSaveName = () => {
        if (name.trim()) {
            network.setDeviceName(name.trim());
            setSaved(true);
            setTimeout(() => setSaved(false), 2000);
        }
    };

    const handleAvatarSelect = (emoji) => {
        updateDeviceEmoji(identity, emoji);
        setShowAvatars(false);
    };

    const handleClearData = async () => {
        if (confirm('This will delete all messages, peers, and AI history. Continue?')) {
            await clearAllData();
            window.location.reload();
        }
    };

    return (
        <div className="view-container settings-view">
            <h2>⚙️ Settings</h2>

            {/* Device Identity */}
            <div className="settings-section">
                <h3>📱 Device Identity</h3>
                <div className="settings-card">
                    <div className="identity-display">
                        <button className="avatar-btn" onClick={() => setShowAvatars(!showAvatars)}>
                            {identity.emoji}
                        </button>
                        <div className="identity-info">
                            <div className="identity-id">ID: {identity.id.slice(0, 8)}...</div>
                        </div>
                    </div>

                    {showAvatars && (
                        <div className="avatar-picker">
                            {AVATAR_OPTIONS.map(emoji => (
                                <button
                                    key={emoji}
                                    className={`avatar-option ${emoji === identity.emoji ? 'selected' : ''}`}
                                    onClick={() => handleAvatarSelect(emoji)}
                                >
                                    {emoji}
                                </button>
                            ))}
                        </div>
                    )}

                    <div className="settings-field">
                        <label>Display Name</label>
                        <div className="input-row">
                            <input
                                type="text"
                                value={name}
                                onChange={(e) => setName(e.target.value)}
                                placeholder="Your name"
                                maxLength={30}
                            />
                            <button className="save-btn" onClick={handleSaveName}>
                                {saved ? '✓ Saved' : 'Save'}
                            </button>
                        </div>
                    </div>
                </div>
            </div>

            {/* Network Status */}
            <div className="settings-section">
                <h3>📊 Network Status</h3>
                <div className="settings-card">
                    <div className="stat-row">
                        <span>Bluetooth</span>
                        <span className={stats.bluetoothSupported ? 'status-on' : 'status-off'}>
                            {stats.bluetoothSupported ? '✅ Supported' : '❌ Not Available'}
                        </span>
                    </div>
                    <div className="stat-row">
                        <span>Connected Peers</span>
                        <span>{stats.connectedPeers}</span>
                    </div>
                    <div className="stat-row">
                        <span>Total Messages</span>
                        <span>{stats.totalMessages}</span>
                    </div>
                    <div className="stat-row">
                        <span>Device ID</span>
                        <span className="mono">{stats.deviceId.slice(0, 12)}...</span>
                    </div>
                </div>
            </div>

            {/* Offline Status */}
            <div className="settings-section">
                <h3>📶 Offline Mode</h3>
                <div className="settings-card">
                    <div className="stat-row">
                        <span>App Mode</span>
                        <span className="status-on">✅ Fully Offline</span>
                    </div>
                    <div className="stat-row">
                        <span>AI Assistant</span>
                        <span className="status-on">✅ On-Device</span>
                    </div>
                    <div className="stat-row">
                        <span>Encryption</span>
                        <span className="status-on">🔒 AES-256-GCM</span>
                    </div>
                    <div className="stat-row">
                        <span>Storage</span>
                        <span>IndexedDB (Local)</span>
                    </div>
                </div>
            </div>

            {/* Danger Zone */}
            <div className="settings-section danger">
                <h3>⚠️ Data Management</h3>
                <div className="settings-card">
                    <p className="danger-text">Clear all local data including messages, peer history, and AI conversations.</p>
                    <button className="danger-btn" onClick={handleClearData}>
                        🗑️ Clear All Data
                    </button>
                </div>
            </div>

            {/* About */}
            <div className="settings-section">
                <h3>ℹ️ About</h3>
                <div className="settings-card about-card">
                    <div className="about-title">📡 MeshLink v2.0</div>
                    <p>Portable AI-Assisted Offline Communication System Using Decentralized Mesh Networking</p>
                    <div className="about-features">
                        <span>🔗 Bluetooth Mesh</span>
                        <span>🤖 Offline AI</span>
                        <span>🔒 E2E Encryption</span>
                        <span>📱 PWA</span>
                    </div>
                </div>
            </div>
        </div>
    );
}
