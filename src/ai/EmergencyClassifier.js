/**
 * EmergencyClassifier — Lightweight NLP classifier for emergency message detection.
 * Uses a keyword-based fast path with weighted scoring for real-time classification.
 * Designed to run entirely on-device with zero cloud dependency.
 */

// Emergency keyword categories with weights
const EMERGENCY_PATTERNS = {
    immediate_danger: {
        weight: 1.0,
        keywords: ['sos', 'help', 'emergency', 'mayday', 'rescue', 'save me', 'dying', 'trapped', 'stuck', 'danger', 'critical'],
    },
    natural_disaster: {
        weight: 0.9,
        keywords: ['earthquake', 'tsunami', 'flood', 'hurricane', 'tornado', 'cyclone', 'landslide', 'avalanche', 'wildfire', 'volcano', 'storm'],
    },
    medical: {
        weight: 0.85,
        keywords: ['injured', 'bleeding', 'unconscious', 'heart attack', 'stroke', 'broken bone', 'fracture', 'ambulance', 'medical', 'wound', 'pain', 'medicine', 'doctor', 'hospital'],
    },
    fire: {
        weight: 0.9,
        keywords: ['fire', 'burning', 'smoke', 'explosion', 'blast', 'flames', 'arson'],
    },
    structural: {
        weight: 0.85,
        keywords: ['collapsed', 'collapse', 'building down', 'rubble', 'debris', 'crumbling', 'structural damage', 'destroyed'],
    },
    evacuation: {
        weight: 0.8,
        keywords: ['evacuate', 'evacuation', 'flee', 'escape', 'shelter', 'safe zone', 'assembly point', 'get out'],
    },
    supplies: {
        weight: 0.7,
        keywords: ['food', 'water', 'supplies', 'shortage', 'starving', 'dehydrated', 'ration', 'need water', 'need food'],
    },
    people: {
        weight: 0.75,
        keywords: ['missing', 'lost', 'children', 'elderly', 'survivors', 'casualties', 'victims', 'dead', 'alive', 'found people'],
    },
};

// Urgency amplifiers
const URGENCY_AMPLIFIERS = [
    { pattern: /!{2,}/g, boost: 0.1 },
    { pattern: /HELP/g, boost: 0.15 },
    { pattern: /URGENT/gi, boost: 0.15 },
    { pattern: /ASAP/gi, boost: 0.1 },
    { pattern: /immediately/gi, boost: 0.1 },
    { pattern: /right now/gi, boost: 0.1 },
    { pattern: /please help/gi, boost: 0.12 },
    { pattern: /\b\d+\s*(people|persons|victims|casualties|injured|dead|trapped)/gi, boost: 0.15 },
];

/**
 * Classify a message for emergency content.
 * @param {string} text - The message text to classify
 * @returns {{ isEmergency: boolean, confidence: number, category: string, categories: string[], urgencyScore: number }}
 */
export function classifyMessage(text) {
    if (!text || text.trim().length === 0) {
        return {
            isEmergency: false,
            confidence: 0,
            category: 'none',
            categories: [],
            urgencyScore: 0,
        };
    }

    const lowerText = text.toLowerCase();
    const matchedCategories = [];
    let totalScore = 0;
    let maxWeight = 0;
    let primaryCategory = 'none';

    // Check each emergency category
    for (const [category, { weight, keywords }] of Object.entries(EMERGENCY_PATTERNS)) {
        let categoryHits = 0;
        for (const keyword of keywords) {
            if (lowerText.includes(keyword)) {
                categoryHits++;
            }
        }

        if (categoryHits > 0) {
            const categoryScore = weight * Math.min(categoryHits / 2, 1); // diminishing returns
            totalScore += categoryScore;
            matchedCategories.push({ category, score: categoryScore, hits: categoryHits });

            if (categoryScore > maxWeight) {
                maxWeight = categoryScore;
                primaryCategory = category;
            }
        }
    }

    // Apply urgency amplifiers
    let urgencyBoost = 0;
    for (const { pattern, boost } of URGENCY_AMPLIFIERS) {
        if (pattern.test(text)) {
            urgencyBoost += boost;
        }
        // Reset regex lastIndex
        pattern.lastIndex = 0;
    }

    // Calculate final confidence (0-1 range)
    const rawConfidence = Math.min(totalScore + urgencyBoost, 1);
    const confidence = Math.round(rawConfidence * 100) / 100;

    // Determine urgency score (0-10)
    const urgencyScore = Math.min(Math.round(rawConfidence * 10), 10);

    return {
        isEmergency: confidence >= 0.3,
        confidence,
        category: primaryCategory,
        categories: matchedCategories.map(c => c.category),
        urgencyScore,
        details: matchedCategories,
    };
}

/**
 * Get a human-readable label for the emergency category.
 */
export function getCategoryLabel(category) {
    const labels = {
        immediate_danger: '🚨 Immediate Danger',
        natural_disaster: '🌊 Natural Disaster',
        medical: '🏥 Medical Emergency',
        fire: '🔥 Fire/Explosion',
        structural: '🏗️ Structural Collapse',
        evacuation: '🏃 Evacuation',
        supplies: '📦 Supply Shortage',
        people: '👥 People in Need',
        none: '✉️ General Message',
    };
    return labels[category] || '✉️ General Message';
}

/**
 * Get a color for the urgency level.
 */
export function getUrgencyColor(urgencyScore) {
    if (urgencyScore >= 8) return '#ff1744';  // critical red
    if (urgencyScore >= 6) return '#ff9100';  // high orange
    if (urgencyScore >= 4) return '#ffea00';  // medium yellow
    if (urgencyScore >= 2) return '#00e676';  // low green
    return '#90a4ae';                          // minimal gray
}
