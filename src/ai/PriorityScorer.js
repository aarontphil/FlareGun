/**
 * PriorityScorer — Assigns message priority based on AI classification
 * and user-specified priority. Combines multiple signals into a final
 * priority level that affects routing behavior.
 */

import { MessagePriority } from '../mesh/MessageRouter.js';

/**
 * Priority levels with numeric values for comparison.
 */
const PRIORITY_VALUES = {
    [MessagePriority.CRITICAL]: 4,
    [MessagePriority.HIGH]: 3,
    [MessagePriority.MEDIUM]: 2,
    [MessagePriority.LOW]: 1,
};

/**
 * Score and assign priority to a message based on AI analysis.
 * @param {object} aiAnalysis - Result from EmergencyClassifier
 * @param {string} userPriority - User-selected priority level
 * @returns {{ priority: string, score: number, reason: string, ttlBoost: number }}
 */
export function scoreMessagePriority(aiAnalysis, userPriority = MessagePriority.MEDIUM) {
    let score = PRIORITY_VALUES[userPriority] || 2;
    let reason = 'User-set priority';

    if (aiAnalysis && aiAnalysis.isEmergency) {
        // AI detected emergency content
        const aiScore = Math.ceil(aiAnalysis.urgencyScore / 2.5); // 0-10 → 1-4
        if (aiScore > score) {
            score = aiScore;
            reason = `AI detected: ${aiAnalysis.category} (${Math.round(aiAnalysis.confidence * 100)}% confidence)`;
        }
    }

    // Determine final priority level
    let priority;
    if (score >= 4) priority = MessagePriority.CRITICAL;
    else if (score >= 3) priority = MessagePriority.HIGH;
    else if (score >= 2) priority = MessagePriority.MEDIUM;
    else priority = MessagePriority.LOW;

    // TTL boost for higher priority messages
    const ttlBoost = score >= 3 ? 5 : 0; // Critical/High get +5 TTL

    return { priority, score, reason, ttlBoost };
}

/**
 * Get priority badge styling.
 */
export function getPriorityStyle(priority) {
    const styles = {
        [MessagePriority.CRITICAL]: {
            color: '#fff',
            background: 'linear-gradient(135deg, #ff1744, #d50000)',
            label: '🔴 CRITICAL',
            animate: true,
        },
        [MessagePriority.HIGH]: {
            color: '#fff',
            background: 'linear-gradient(135deg, #ff9100, #ff6d00)',
            label: '🟠 HIGH',
            animate: false,
        },
        [MessagePriority.MEDIUM]: {
            color: '#1a1a2e',
            background: 'linear-gradient(135deg, #ffea00, #ffd600)',
            label: '🟡 MEDIUM',
            animate: false,
        },
        [MessagePriority.LOW]: {
            color: '#1a1a2e',
            background: 'linear-gradient(135deg, #00e676, #00c853)',
            label: '🟢 LOW',
            animate: false,
        },
    };
    return styles[priority] || styles[MessagePriority.MEDIUM];
}

/**
 * Sort messages by priority (highest first), then by timestamp.
 */
export function sortByPriority(messages) {
    return [...messages].sort((a, b) => {
        const priorityA = PRIORITY_VALUES[a.priority] || 2;
        const priorityB = PRIORITY_VALUES[b.priority] || 2;
        if (priorityB !== priorityA) return priorityB - priorityA;
        return b.timestamp - a.timestamp;
    });
}
