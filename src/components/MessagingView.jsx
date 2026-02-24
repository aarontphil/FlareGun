import React, { useState, useRef, useEffect } from 'react';
import { classifyMessage, getCategoryLabel, getUrgencyColor } from '../ai/EmergencyClassifier.js';
import { getPriorityColor, getPriorityLabel, MessagePriority } from '../mesh/MessageRouter.js';

export default function MessagingView({ network, messages }) {
    const [text, setText] = useState('');
    const [priority, setPriority] = useState('normal');
    const [showPriorityPicker, setShowPriorityPicker] = useState(false);
    const [sending, setSending] = useState(false);
    const scrollRef = useRef(null);
    const inputRef = useRef(null);

    const identity = network.getIdentity();

    useEffect(() => {
        if (scrollRef.current) {
            scrollRef.current.scrollTop = scrollRef.current.scrollHeight;
        }
    }, [messages]);

    const handleSend = async () => {
        if (!text.trim() || sending) return;
        setSending(true);
        try {
            await network.sendMessage(text.trim(), priority);
            setText('');
            setPriority('normal');
        } catch (err) {
            console.error('Send failed:', err);
        }
        setSending(false);
        inputRef.current?.focus();
    };

    const handleKeyDown = (e) => {
        if (e.key === 'Enter' && !e.shiftKey) {
            e.preventDefault();
            handleSend();
        }
    };

    const formatTime = (ts) => {
        const d = new Date(ts);
        return d.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
    };

    const stats = network.getStats();

    return (
        <div className="view-container messaging-view">
            {/* Header bar */}
            <div className="messaging-header">
                <div className="messaging-header-info">
                    <h2>💬 Messages</h2>
                    <span className="peer-badge">
                        {stats.connectedPeers > 0
                            ? `🟢 ${stats.connectedPeers} peer${stats.connectedPeers > 1 ? 's' : ''}`
                            : '🔴 No peers'
                        }
                    </span>
                </div>
                {!stats.bluetoothSupported && (
                    <div className="ble-warning">📱 Open this app on your phone for Bluetooth mesh</div>
                )}
            </div>

            {/* Messages list */}
            <div className="messages-list" ref={scrollRef}>
                {messages.length === 0 ? (
                    <div className="empty-state">
                        <div className="empty-icon">📡</div>
                        <h3>No messages yet</h3>
                        <p>Send a message or connect to nearby peers via Bluetooth</p>
                    </div>
                ) : (
                    messages.map((msg, i) => {
                        const isOwn = msg.senderId === identity.id;
                        const classification = classifyMessage(msg.text);
                        return (
                            <div key={msg.id || i} className={`message-bubble ${isOwn ? 'own' : 'peer'} ${classification.isEmergency ? 'emergency' : ''}`}>
                                {!isOwn && (
                                    <div className="message-sender">
                                        <span className="sender-emoji">{msg.senderEmoji || '📱'}</span>
                                        <span className="sender-name">{msg.senderName || 'Unknown'}</span>
                                    </div>
                                )}
                                <div className="message-text">{msg.text}</div>
                                <div className="message-meta">
                                    {msg.priority && msg.priority !== 'normal' && (
                                        <span className="priority-tag" style={{ color: getPriorityColor(msg.priority) }}>
                                            {getPriorityLabel(msg.priority)}
                                        </span>
                                    )}
                                    {classification.isEmergency && (
                                        <span className="urgency-tag" style={{ color: getUrgencyColor(classification.urgencyScore) }}>
                                            {getCategoryLabel(classification.category)}
                                        </span>
                                    )}
                                    <span className="message-time">{formatTime(msg.timestamp)}</span>
                                    {isOwn && msg.relayCount > 0 && (
                                        <span className="relay-tag">📡 relayed ×{msg.relayCount}</span>
                                    )}
                                </div>
                            </div>
                        );
                    })
                )}
            </div>

            {/* Compose bar */}
            <div className="compose-bar">
                <button
                    className={`priority-btn ${priority !== 'normal' ? 'active' : ''}`}
                    onClick={() => setShowPriorityPicker(!showPriorityPicker)}
                    style={priority !== 'normal' ? { color: getPriorityColor(priority) } : {}}
                    title="Set priority"
                >
                    {priority === 'critical' ? '🚨' : priority === 'high' ? '⚠️' : '📩'}
                </button>

                {showPriorityPicker && (
                    <div className="priority-picker">
                        {Object.entries(MessagePriority).map(([key, value]) => (
                            <button
                                key={key}
                                className={`priority-option ${priority === value ? 'selected' : ''}`}
                                onClick={() => { setPriority(value); setShowPriorityPicker(false); }}
                            >
                                <span style={{ color: getPriorityColor(value) }}>{getPriorityLabel(value)}</span>
                            </button>
                        ))}
                    </div>
                )}

                <textarea
                    ref={inputRef}
                    className="compose-input"
                    placeholder="Type a message..."
                    value={text}
                    onChange={(e) => setText(e.target.value)}
                    onKeyDown={handleKeyDown}
                    rows={1}
                />

                <button
                    className="send-btn"
                    onClick={handleSend}
                    disabled={!text.trim() || sending}
                >
                    {sending ? '⏳' : '➤'}
                </button>
            </div>
        </div>
    );
}
