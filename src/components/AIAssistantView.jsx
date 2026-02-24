import React, { useState, useRef, useEffect } from 'react';
import { AIAssistant, QUICK_ACTIONS } from '../ai/AIAssistant.js';
import { getAllCategories } from '../ai/DisasterKnowledge.js';

const assistant = new AIAssistant();

export default function AIAssistantView() {
    const [messages, setMessages] = useState([]);
    const [input, setInput] = useState('');
    const [showCategories, setShowCategories] = useState(false);
    const scrollRef = useRef(null);
    const inputRef = useRef(null);

    useEffect(() => {
        // Send initial greeting
        if (messages.length === 0) {
            const response = assistant.respond('hello');
            setMessages([{
                role: 'assistant',
                text: response.text,
                type: response.type,
                timestamp: Date.now(),
            }]);
        }
    }, []);

    useEffect(() => {
        if (scrollRef.current) {
            scrollRef.current.scrollTop = scrollRef.current.scrollHeight;
        }
    }, [messages]);

    const sendMessage = (text) => {
        if (!text.trim()) return;

        const userMsg = { role: 'user', text: text.trim(), timestamp: Date.now() };
        const response = assistant.respond(text.trim());
        const aiMsg = {
            role: 'assistant',
            text: response.text,
            type: response.type,
            data: response.data,
            timestamp: Date.now(),
        };

        setMessages(prev => [...prev, userMsg, aiMsg]);
        setInput('');
        inputRef.current?.focus();
    };

    const handleQuickAction = (actionId) => {
        const response = assistant.handleQuickAction(actionId);
        const action = QUICK_ACTIONS.find(a => a.id === actionId);

        setMessages(prev => [
            ...prev,
            { role: 'user', text: action?.description || actionId, timestamp: Date.now() },
            { role: 'assistant', text: response.text, type: response.type, data: response.data, timestamp: Date.now() },
        ]);
    };

    const handleKeyDown = (e) => {
        if (e.key === 'Enter' && !e.shiftKey) {
            e.preventDefault();
            sendMessage(input);
        }
    };

    const handleClear = () => {
        assistant.clearHistory();
        setMessages([]);
        // Re-greet
        const response = assistant.respond('hello');
        setMessages([{
            role: 'assistant',
            text: response.text,
            type: response.type,
            timestamp: Date.now(),
        }]);
    };

    const categories = getAllCategories();

    const renderMarkdown = (text) => {
        // Simple markdown rendering for bold, newlines, and bullets
        return text
            .split('\n')
            .map((line, i) => {
                // Bold
                let rendered = line.replace(/\*\*(.+?)\*\*/g, '<strong>$1</strong>');
                // Italic
                rendered = rendered.replace(/\*(.+?)\*/g, '<em>$1</em>');
                // Bullet points
                if (rendered.trim().startsWith('•') || rendered.trim().startsWith('-')) {
                    return `<div class="md-bullet" key="${i}">${rendered}</div>`;
                }
                return rendered;
            })
            .join('<br/>');
    };

    return (
        <div className="view-container ai-view">
            <div className="ai-header">
                <div className="ai-header-left">
                    <h2>🤖 AI Assistant</h2>
                    <span className="ai-badge">Offline</span>
                </div>
                <div className="ai-header-right">
                    <button className="icon-btn" onClick={() => setShowCategories(!showCategories)} title="Browse topics">
                        📚
                    </button>
                    <button className="icon-btn" onClick={handleClear} title="Clear chat">
                        🗑️
                    </button>
                </div>
            </div>

            {/* Category browser */}
            {showCategories && (
                <div className="category-browser">
                    <h3>📚 Knowledge Base</h3>
                    {categories.map(cat => (
                        <div key={cat.key} className="category-group">
                            <div className="category-title">{cat.label}</div>
                            <div className="category-topics">
                                {cat.topics.map(topic => (
                                    <button
                                        key={topic.key}
                                        className="topic-chip"
                                        onClick={() => {
                                            setShowCategories(false);
                                            sendMessage(topic.title);
                                        }}
                                    >
                                        {topic.title}
                                    </button>
                                ))}
                            </div>
                        </div>
                    ))}
                </div>
            )}

            {/* Quick actions */}
            <div className="quick-actions">
                {QUICK_ACTIONS.map(action => (
                    <button
                        key={action.id}
                        className={`quick-action-btn ${action.id === 'sos' ? 'sos' : ''}`}
                        onClick={() => handleQuickAction(action.id)}
                    >
                        <span className="qa-label">{action.label}</span>
                    </button>
                ))}
            </div>

            {/* Chat messages */}
            <div className="ai-messages" ref={scrollRef}>
                {messages.map((msg, i) => (
                    <div key={i} className={`ai-message ${msg.role} ${msg.type === 'emergency' ? 'emergency' : ''}`}>
                        {msg.role === 'assistant' && <div className="ai-avatar">🤖</div>}
                        <div
                            className="ai-message-content"
                            dangerouslySetInnerHTML={{ __html: renderMarkdown(msg.text) }}
                        />
                    </div>
                ))}
            </div>

            {/* Input */}
            <div className="ai-compose">
                <textarea
                    ref={inputRef}
                    className="ai-input"
                    placeholder="Ask me anything about disaster survival..."
                    value={input}
                    onChange={(e) => setInput(e.target.value)}
                    onKeyDown={handleKeyDown}
                    rows={1}
                />
                <button
                    className="send-btn"
                    onClick={() => sendMessage(input)}
                    disabled={!input.trim()}
                >
                    ➤
                </button>
            </div>
        </div>
    );
}
