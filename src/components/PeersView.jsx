import React from 'react';
import { PeerManager } from '../mesh/PeerDiscovery.js';

export default function PeersView({ network }) {
    const stats = network.getStats();
    const peers = network.getAllPeers();
    const connectedPeers = network.getConnectedPeers();

    const handleScan = async () => {
        try {
            await network.scanForPeers();
        } catch (err) {
            alert(err.message);
        }
    };

    const handleDisconnect = (deviceId) => {
        network.disconnectPeer(deviceId);
    };

    return (
        <div className="view-container peers-view">
            <div className="peers-header">
                <h2>📡 Nearby Peers</h2>
                <div className="peer-stats">
                    <span className="stat-chip connected">🟢 {stats.connectedPeers} Connected</span>
                    <span className="stat-chip total">📱 {stats.totalPeers} Discovered</span>
                </div>
            </div>

            {/* WebSocket Relay Status */}
            <div className={`ble-status-card ${stats.wsConnected ? 'supported' : 'unsupported'}`}>
                <div className="ble-status-icon">
                    {stats.wsConnected ? '🌐' : '📵'}
                </div>
                <div className="ble-status-text">
                    <strong>{stats.wsConnected ? 'Mesh Relay Connected' : 'Mesh Relay Disconnected'}</strong>
                    <p>
                        {stats.wsConnected
                            ? `Connected to relay — devices on same WiFi auto-discover each other`
                            : 'Relay server not running. Start with: npm run relay'
                        }
                    </p>
                </div>
            </div>

            {/* BLE Status */}
            {!stats.wsConnected && (
                <div className={`ble-status-card ${stats.bluetoothSupported ? 'supported' : 'unsupported'}`}>
                    <div className="ble-status-icon">
                        {stats.bluetoothSupported ? '📶' : '📵'}
                    </div>
                    <div className="ble-status-text">
                        <strong>{stats.bluetoothSupported ? 'Bluetooth Ready' : 'Bluetooth Not Available'}</strong>
                        <p>
                            {stats.bluetoothSupported
                                ? 'Scan for nearby MeshLink devices to connect'
                                : 'Open this app on Android Chrome for Bluetooth mesh'
                            }
                        </p>
                    </div>
                </div>
            )}

            {/* Scan button — shows for BLE when WS is not connected */}
            {!stats.wsConnected && (
                <button
                    className="scan-btn"
                    onClick={handleScan}
                    disabled={!stats.bluetoothSupported || stats.isScanning}
                >
                    {stats.isScanning ? (
                        <>
                            <span className="scan-spinner">⏳</span> Scanning...
                        </>
                    ) : (
                        <>
                            <span>🔍</span> Scan for Peers
                        </>
                    )}
                </button>
            )}

            {/* Connected peers */}
            {connectedPeers.length > 0 && (
                <div className="peer-section">
                    <h3>Connected</h3>
                    {connectedPeers.map(peer => (
                        <div key={peer.deviceId} className="peer-card connected">
                            <div className="peer-avatar">{peer.emoji || '📱'}</div>
                            <div className="peer-info">
                                <div className="peer-name">{peer.name}</div>
                                <div className="peer-detail">
                                    🟢 Connected · {PeerManager.formatLastSeen(peer.lastSeen)}
                                </div>
                                {peer.messageCount > 0 && (
                                    <div className="peer-detail">{peer.messageCount} messages exchanged</div>
                                )}
                            </div>
                            <button
                                className="disconnect-btn"
                                onClick={() => handleDisconnect(peer.deviceId)}
                            >
                                ❌
                            </button>
                        </div>
                    ))}
                </div>
            )}

            {/* All discovered peers */}
            {peers.length > 0 && (
                <div className="peer-section">
                    <h3>All Discovered ({peers.length})</h3>
                    {peers.filter(p => !p.connected).map(peer => (
                        <div key={peer.deviceId} className="peer-card offline">
                            <div className="peer-avatar">{peer.emoji || '📱'}</div>
                            <div className="peer-info">
                                <div className="peer-name">{peer.name}</div>
                                <div className="peer-detail">
                                    ⚪ Last seen {PeerManager.formatLastSeen(peer.lastSeen)}
                                </div>
                            </div>
                        </div>
                    ))}
                </div>
            )}

            {/* Empty state */}
            {peers.length === 0 && (
                <div className="empty-state">
                    <div className="empty-icon">📡</div>
                    <h3>No peers discovered</h3>
                    <p>
                        {stats.wsConnected
                            ? 'Open this app on another device connected to the same WiFi'
                            : 'Start the relay server or scan for Bluetooth peers'
                        }
                    </p>
                    <div className="mesh-tips">
                        <h4>📋 Multi-Device Setup</h4>
                        <ul>
                            <li>Connect all devices to the same WiFi network</li>
                            <li>Run <code>npm run relay</code> on the host machine</li>
                            <li>Open the app URL on each device's browser</li>
                            <li>Peers auto-discover — no pairing needed!</li>
                        </ul>
                    </div>
                </div>
            )}
        </div>
    );
}
