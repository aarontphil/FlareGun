import React, { useState, useEffect, useCallback } from 'react';
import { MeshNetwork } from './mesh/MeshNetwork.js';
import MessagingView from './components/MessagingView.jsx';
import PeersView from './components/PeersView.jsx';
import AIAssistantView from './components/AIAssistantView.jsx';
import SettingsView from './components/SettingsView.jsx';

// Create the global network instance
const network = new MeshNetwork();

const TABS = [
    { id: 'chat', label: 'Chat', icon: '💬', component: 'messaging' },
    { id: 'peers', label: 'Peers', icon: '📡', component: 'peers' },
    { id: 'ai', label: 'AI', icon: '🤖', component: 'ai' },
    { id: 'settings', label: 'Settings', icon: '⚙️', component: 'settings' },
];

export default function App() {
    const [activeTab, setActiveTab] = useState('chat');
    const [messages, setMessages] = useState([]);
    const [stats, setStats] = useState(network.getStats());
    const [, forceUpdate] = useState(0);

    // Subscribe to network state changes
    useEffect(() => {
        const unsub = network.subscribe(() => {
            setMessages(network.getMessages());
            setStats(network.getStats());
            forceUpdate(n => n + 1);
        });

        // Initial load
        setMessages(network.getMessages());
        setStats(network.getStats());

        return unsub;
    }, []);

    // Vibrate on new emergency message
    useEffect(() => {
        if (messages.length > 0) {
            const last = messages[messages.length - 1];
            if (last.priority === 'critical' && last.senderId !== network.getIdentity().id) {
                if (navigator.vibrate) navigator.vibrate([200, 100, 200]);
            }
        }
    }, [messages.length]);

    const renderView = () => {
        switch (activeTab) {
            case 'chat':
                return <MessagingView network={network} messages={messages} />;
            case 'peers':
                return <PeersView network={network} />;
            case 'ai':
                return <AIAssistantView />;
            case 'settings':
                return <SettingsView network={network} />;
            default:
                return <MessagingView network={network} messages={messages} />;
        }
    };

    const unreadEmergency = messages.filter(
        m => m.priority === 'critical' && m.senderId !== network.getIdentity().id
    ).length;

    return (
        <div className="app">
            {/* Splash header */}
            <header className="app-header">
                <div className="app-brand">
                    <span className="app-logo">📡</span>
                    <span className="app-title">MeshLink</span>
                </div>
                <div className="header-status">
                    {stats.connectedPeers > 0 ? (
                        <span className="status-online">🟢 {stats.connectedPeers}</span>
                    ) : (
                        <span className="status-offline">Offline</span>
                    )}
                </div>
            </header>

            {/* Main content */}
            <main className="app-main">
                {renderView()}
            </main>

            {/* Bottom tab bar */}
            <nav className="tab-bar">
                {TABS.map(tab => (
                    <button
                        key={tab.id}
                        className={`tab-item ${activeTab === tab.id ? 'active' : ''}`}
                        onClick={() => setActiveTab(tab.id)}
                    >
                        <span className="tab-icon">
                            {tab.icon}
                            {tab.id === 'chat' && unreadEmergency > 0 && (
                                <span className="tab-badge">{unreadEmergency}</span>
                            )}
                        </span>
                        <span className="tab-label">{tab.label}</span>
                    </button>
                ))}
            </nav>
        </div>
    );
}
