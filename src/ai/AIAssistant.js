/**
 * AIAssistant — Decentralized on-device AI assistant for disaster situations.
 * Uses intent detection + knowledge base to provide actionable guidance.
 * Works 100% offline — no cloud APIs needed.
 */
import { searchKnowledge, getAllCategories, getTopic } from './DisasterKnowledge.js';
import { classifyMessage, getCategoryLabel } from './EmergencyClassifier.js';
import { summarizeMessage } from './Summarizer.js';

/**
 * Intent patterns for conversation routing.
 */
const INTENT_PATTERNS = [
    { intent: 'greeting', patterns: [/^(hi|hello|hey|help me|assist)/i], priority: 1 },
    { intent: 'sos', patterns: [/\b(sos|mayday|emergency|help)\b/i, /\b(danger|trapped|dying)\b/i], priority: 10 },
    { intent: 'first_aid', patterns: [/\b(cpr|bleeding|burn|fracture|broken|wound|injury|injured|shock|unconscious|choking)\b/i], priority: 8 },
    { intent: 'disaster', patterns: [/\b(earthquake|flood|tsunami|hurricane|cyclone|tornado|landslide|wildfire)\b/i], priority: 8 },
    { intent: 'shelter', patterns: [/\b(shelter|build shelter|cold|hypothermia|camp|sleep|exposed|tent)\b/i], priority: 6 },
    { intent: 'water', patterns: [/\b(water|purif|dehydrat|thirst|drink|boil water)\b/i], priority: 7 },
    { intent: 'fire', patterns: [/\b(start fire|campfire|warmth|fire starting|light fire|make fire)\b/i], priority: 5 },
    { intent: 'signal', patterns: [/\b(signal|rescue|sos signal|mirror|flare|found me|search)\b/i], priority: 7 },
    { intent: 'navigate', patterns: [/\b(lost|navigate|direction|compass|north|south|which way|find way)\b/i], priority: 6 },
    { intent: 'mesh_help', patterns: [/\b(mesh|meshlink|bluetooth|connect|network|how to use|app help|pair)\b/i], priority: 4 },
    { intent: 'analyze', patterns: [/\b(analyze|classify|priority|urgent|summarize|what does)\b/i], priority: 3 },
    { intent: 'categories', patterns: [/\b(what can you|topics|categories|list|show me|help with)\b/i], priority: 2 },
];

/**
 * Quick action definitions for the UI.
 */
export const QUICK_ACTIONS = [
    { id: 'sos', label: '🚨 Send SOS', description: 'Get help sending an emergency broadcast', intent: 'sos' },
    { id: 'first_aid', label: '🩹 First Aid', description: 'Step-by-step medical guidance', intent: 'first_aid' },
    { id: 'shelter', label: '🏕️ Build Shelter', description: 'Emergency shelter construction', intent: 'shelter' },
    { id: 'water', label: '💧 Find Water', description: 'Water finding and purification', intent: 'water' },
    { id: 'signal', label: '📡 Signal Rescue', description: 'How to signal for help', intent: 'signal' },
    { id: 'navigate', label: '🧭 Navigate', description: 'Find direction without tools', intent: 'navigate' },
];

/**
 * AIAssistant — interactive offline assistant.
 */
export class AIAssistant {
    constructor() {
        this.conversationHistory = [];
        this.context = {
            lastIntent: null,
            lastTopic: null,
            emergencyMode: false,
        };
    }

    /**
     * Process a user message and generate a response.
     */
    respond(userMessage) {
        const timestamp = Date.now();

        // Store user message
        this.conversationHistory.push({
            role: 'user',
            text: userMessage,
            timestamp,
        });

        // Detect intent
        const intent = this._detectIntent(userMessage);

        // Generate response
        let response;
        switch (intent) {
            case 'greeting':
                response = this._handleGreeting();
                break;
            case 'sos':
                response = this._handleSOS(userMessage);
                break;
            case 'categories':
                response = this._handleCategories();
                break;
            case 'analyze':
                response = this._handleAnalyze(userMessage);
                break;
            default:
                response = this._handleKnowledgeQuery(userMessage, intent);
        }

        // Store assistant response
        this.conversationHistory.push({
            role: 'assistant',
            text: response.text,
            data: response.data || null,
            timestamp: Date.now(),
        });

        return response;
    }

    /**
     * Get conversation history.
     */
    getHistory() {
        return [...this.conversationHistory];
    }

    /**
     * Clear conversation.
     */
    clearHistory() {
        this.conversationHistory = [];
        this.context = { lastIntent: null, lastTopic: null, emergencyMode: false };
    }

    /**
     * Handle a quick action by ID.
     */
    handleQuickAction(actionId) {
        const action = QUICK_ACTIONS.find(a => a.id === actionId);
        if (!action) return this.respond('help');

        const queries = {
            sos: 'I need to send an SOS emergency signal',
            first_aid: 'Show me first aid topics',
            shelter: 'How do I build an emergency shelter?',
            water: 'How do I find and purify water?',
            signal: 'How do I signal for rescue?',
            navigate: 'I\'m lost, how do I find my way?',
        };

        return this.respond(queries[actionId] || 'help');
    }

    // ─── Private Methods ──────────────────

    _detectIntent(text) {
        let bestIntent = 'categories';
        let bestPriority = 0;

        for (const { intent, patterns, priority } of INTENT_PATTERNS) {
            for (const pattern of patterns) {
                if (pattern.test(text) && priority > bestPriority) {
                    bestIntent = intent;
                    bestPriority = priority;
                }
            }
        }

        this.context.lastIntent = bestIntent;
        return bestIntent;
    }

    _handleGreeting() {
        return {
            text: `👋 **I'm MeshLink AI — your offline disaster assistant.**\n\nI can help you with:\n\n🩹 **First Aid** — CPR, bleeding, burns, fractures\n🌊 **Disaster Response** — earthquake, flood, hurricane, tsunami\n🏕️ **Survival** — shelter, water, fire, signaling\n📡 **Communication** — SOS protocols, mesh networking tips\n🧭 **Navigation** — finding direction without tools\n\nJust ask me anything, or tap a quick action below!`,
            type: 'info',
        };
    }

    _handleSOS(text) {
        this.context.emergencyMode = true;
        const sosTopics = searchKnowledge('sos signal emergency');
        const sosGuide = sosTopics.length > 0 ? sosTopics[0].topic : null;

        let responseText = `🚨 **EMERGENCY MODE ACTIVATED**\n\n`;
        responseText += `**Immediate Steps:**\n`;
        responseText += `1. Stay calm — panic uses energy you need\n`;
        responseText += `2. Assess your situation — are you injured? In danger?\n`;
        responseText += `3. Use MeshLink to broadcast your emergency:\n`;
        responseText += `   → Go to **Chat** tab → type your message → set priority to **🚨 Critical**\n`;
        responseText += `4. Include in your message: **WHO** you are, **WHERE** you are, **WHAT** happened\n\n`;

        if (sosGuide) {
            responseText += `**SOS Signal Guide:**\n`;
            sosGuide.steps.slice(0, 4).forEach(step => {
                responseText += `• ${step}\n`;
            });
        }

        responseText += `\n💡 *${sosGuide?.tips || 'Keep messages short and clear. Repeat every few minutes.'}*`;

        return {
            text: responseText,
            type: 'emergency',
            data: { emergencyMode: true },
        };
    }

    _handleCategories() {
        const categories = getAllCategories();
        let text = `📚 **Here's everything I can help with:**\n\n`;

        for (const cat of categories) {
            text += `**${cat.label}**\n`;
            for (const topic of cat.topics) {
                text += `  • ${topic.title}\n`;
            }
            text += '\n';
        }

        text += `Just ask about any topic, or try: *"How do I perform CPR?"*`;

        return { text, type: 'info', data: { categories } };
    }

    _handleAnalyze(text) {
        // Remove the "analyze" keyword and classify the rest
        const messageToAnalyze = text.replace(/\b(analyze|classify|priority|summarize)\b/gi, '').trim();
        const classification = classifyMessage(messageToAnalyze);
        const summary = summarizeMessage(messageToAnalyze);

        let responseText = `🔍 **Message Analysis:**\n\n`;
        responseText += `**Emergency:** ${classification.isEmergency ? '⚠️ YES' : '✅ No'}\n`;
        responseText += `**Category:** ${getCategoryLabel(classification.category)}\n`;
        responseText += `**Urgency Score:** ${classification.urgencyScore}/10\n`;
        responseText += `**Confidence:** ${Math.round(classification.confidence * 100)}%\n`;

        if (summary.wasSummarized) {
            responseText += `\n**Summary:** ${summary.summary}`;
        }

        return { text: responseText, type: 'analysis', data: { classification, summary } };
    }

    _handleKnowledgeQuery(text, intent) {
        const results = searchKnowledge(text);

        if (results.length === 0) {
            // Fallback — show categories
            return {
                text: `I couldn't find specific info about that. Here are things I can help with:\n\n${this._getQuickTopicList()}\n\nTry asking about **first aid**, **earthquakes**, **water purification**, or **shelter building**.`,
                type: 'fallback',
            };
        }

        // Show the best matching topic
        const best = results[0];
        const topic = best.topic;

        let responseText = `**${best.categoryLabel} › ${topic.title}**\n\n`;

        // Show steps
        topic.steps.forEach((step, i) => {
            responseText += `**${i + 1}.** ${step}\n`;
        });

        // Show tip
        if (topic.tips) {
            responseText += `\n💡 **Pro Tip:** *${topic.tips}*`;
        }

        // Show related topics
        if (results.length > 1) {
            responseText += `\n\n📋 **Related:** `;
            responseText += results.slice(1, 4).map(r => r.topic.title).join(' • ');
        }

        this.context.lastTopic = `${best.categoryKey}.${best.topicKey}`;

        return { text: responseText, type: 'knowledge', data: { topic: best } };
    }

    _getQuickTopicList() {
        return `🩹 First Aid  •  🌊 Disasters  •  🏕️ Survival  •  📡 Communication  •  🧭 Navigation`;
    }
}
