/**
 * Summarizer — Offline extractive summarization for long messages.
 * Uses TF-IDF-like sentence scoring to extract the most important
 * sentences from a message. Runs entirely on-device.
 */

// Common stop words to exclude from scoring
const STOP_WORDS = new Set([
    'the', 'a', 'an', 'is', 'are', 'was', 'were', 'be', 'been', 'being',
    'have', 'has', 'had', 'do', 'does', 'did', 'will', 'would', 'could',
    'should', 'may', 'might', 'shall', 'can', 'need', 'dare', 'ought',
    'used', 'to', 'of', 'in', 'for', 'on', 'with', 'at', 'by', 'from',
    'as', 'into', 'through', 'during', 'before', 'after', 'above',
    'below', 'between', 'out', 'off', 'over', 'under', 'again',
    'further', 'then', 'once', 'here', 'there', 'when', 'where',
    'why', 'how', 'all', 'both', 'each', 'few', 'more', 'most',
    'other', 'some', 'such', 'no', 'nor', 'not', 'only', 'own',
    'same', 'so', 'than', 'too', 'very', 'just', 'because', 'but',
    'and', 'or', 'if', 'while', 'that', 'this', 'these', 'those',
    'it', 'its', 'i', 'me', 'my', 'we', 'our', 'you', 'your',
    'he', 'him', 'his', 'she', 'her', 'they', 'them', 'their',
    'what', 'which', 'who', 'whom',
]);

// Emergency-relevant boost words
const BOOST_WORDS = new Set([
    'help', 'emergency', 'urgent', 'critical', 'danger', 'rescue',
    'injured', 'trapped', 'fire', 'flood', 'earthquake', 'medical',
    'evacuation', 'survivors', 'casualties', 'supplies', 'shelter',
    'location', 'coordinates', 'status', 'update', 'alert', 'warning',
    'dead', 'alive', 'missing', 'found', 'safe', 'unsafe',
]);

/**
 * Tokenize text into words, filtering out stop words.
 */
function tokenize(text) {
    return text
        .toLowerCase()
        .replace(/[^\w\s]/g, '')
        .split(/\s+/)
        .filter(word => word.length > 1 && !STOP_WORDS.has(word));
}

/**
 * Split text into sentences.
 */
function splitSentences(text) {
    return text
        .split(/(?<=[.!?])\s+/)
        .map(s => s.trim())
        .filter(s => s.length > 5);
}

/**
 * Calculate word frequency map from tokens.
 */
function getWordFrequency(tokens) {
    const freq = {};
    for (const token of tokens) {
        freq[token] = (freq[token] || 0) + 1;
    }
    return freq;
}

/**
 * Score a sentence based on word frequency, position, and emergency relevance.
 */
function scoreSentence(sentence, wordFreq, position, totalSentences) {
    const tokens = tokenize(sentence);
    if (tokens.length === 0) return 0;

    // Term frequency score
    let tfScore = 0;
    for (const token of tokens) {
        tfScore += wordFreq[token] || 0;
    }
    tfScore /= tokens.length; // normalize by sentence length

    // Position score (first and last sentences more important)
    let positionScore = 0;
    if (position === 0) positionScore = 0.3;
    else if (position === totalSentences - 1) positionScore = 0.15;
    else if (position < totalSentences * 0.3) positionScore = 0.1;

    // Emergency keyword boost
    let emergencyBoost = 0;
    for (const token of tokens) {
        if (BOOST_WORDS.has(token)) {
            emergencyBoost += 0.2;
        }
    }
    emergencyBoost = Math.min(emergencyBoost, 0.5);

    // Length penalty (very short or very long sentences)
    let lengthPenalty = 0;
    if (tokens.length < 3) lengthPenalty = -0.2;
    if (tokens.length > 30) lengthPenalty = -0.1;

    return tfScore + positionScore + emergencyBoost + lengthPenalty;
}

/**
 * Summarize a text by extracting the most important sentences.
 * @param {string} text - Input text to summarize
 * @param {number} maxSentences - Maximum sentences in summary (default: 3)
 * @param {number} minTextLength - Minimum text length to trigger summarization (default: 100)
 * @returns {{ summary: string, originalLength: number, summaryLength: number, compressionRatio: number, sentences: { text: string, score: number }[] }}
 */
export function summarizeMessage(text, maxSentences = 3, minTextLength = 100) {
    if (!text || text.length < minTextLength) {
        return {
            summary: text || '',
            originalLength: text ? text.length : 0,
            summaryLength: text ? text.length : 0,
            compressionRatio: 1,
            sentences: [],
            wasSummarized: false,
        };
    }

    const sentences = splitSentences(text);
    if (sentences.length <= maxSentences) {
        return {
            summary: text,
            originalLength: text.length,
            summaryLength: text.length,
            compressionRatio: 1,
            sentences: sentences.map(s => ({ text: s, score: 1 })),
            wasSummarized: false,
        };
    }

    // Get word frequencies across all text
    const allTokens = tokenize(text);
    const wordFreq = getWordFrequency(allTokens);

    // Score each sentence
    const scoredSentences = sentences.map((sentence, index) => ({
        text: sentence,
        score: scoreSentence(sentence, wordFreq, index, sentences.length),
        originalIndex: index,
    }));

    // Sort by score (descending) and take top N
    const topSentences = [...scoredSentences]
        .sort((a, b) => b.score - a.score)
        .slice(0, maxSentences)
        // Re-sort by original position for readability
        .sort((a, b) => a.originalIndex - b.originalIndex);

    const summary = topSentences.map(s => s.text).join(' ');

    return {
        summary,
        originalLength: text.length,
        summaryLength: summary.length,
        compressionRatio: Math.round((summary.length / text.length) * 100) / 100,
        sentences: topSentences,
        wasSummarized: true,
    };
}

/**
 * Quick summary for bandwidth-constrained relay.
 * Returns a very compressed version (1-2 sentences max).
 */
export function quickSummarize(text) {
    return summarizeMessage(text, 2, 50);
}
