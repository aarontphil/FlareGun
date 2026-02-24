"""
Message Summarizer — Offline extractive summarization.
Uses TF-IDF-like scoring with emergency keyword boosting.
"""

import re
import math
from collections import Counter

# Emergency keywords that get extra weight
EMERGENCY_BOOST_WORDS = {
    "help", "emergency", "sos", "danger", "trapped", "injured",
    "fire", "flood", "earthquake", "rescue", "evacuate", "medical",
    "collapse", "missing", "urgent", "critical", "casualties",
    "survivors", "shelter", "supplies", "water", "food",
}

# Common stop words to ignore
STOP_WORDS = {
    "the", "a", "an", "is", "are", "was", "were", "be", "been",
    "being", "have", "has", "had", "do", "does", "did", "will",
    "would", "could", "should", "may", "might", "shall", "can",
    "to", "of", "in", "for", "on", "with", "at", "by", "from",
    "as", "into", "through", "during", "before", "after", "above",
    "below", "between", "out", "off", "over", "under", "again",
    "further", "then", "once", "here", "there", "when", "where",
    "why", "how", "all", "both", "each", "few", "more", "most",
    "other", "some", "such", "no", "nor", "not", "only", "own",
    "same", "so", "than", "too", "very", "just", "but", "and",
    "or", "if", "because", "until", "while", "about", "it", "its",
    "this", "that", "these", "those", "i", "me", "my", "we", "our",
    "you", "your", "he", "him", "his", "she", "her", "they", "them",
    "their", "what", "which", "who", "whom",
}


def _split_sentences(text: str) -> list[str]:
    """Split text into sentences."""
    sentences = re.split(r'[.!?]+', text)
    return [s.strip() for s in sentences if s.strip() and len(s.strip()) > 10]


def _tokenize(text: str) -> list[str]:
    """Tokenize text into words, filtering stop words."""
    words = re.findall(r'\b[a-z]+\b', text.lower())
    return [w for w in words if w not in STOP_WORDS and len(w) > 2]


def _compute_word_freq(sentences: list[str]) -> Counter:
    """Compute word frequency across all sentences."""
    freq = Counter()
    for sentence in sentences:
        freq.update(_tokenize(sentence))
    return freq


def _score_sentence(
    sentence: str,
    word_freq: Counter,
    position: int,
    total: int,
) -> float:
    """Score a sentence based on TF-IDF-like features."""
    tokens = _tokenize(sentence)
    if not tokens:
        return 0.0

    max_freq = max(word_freq.values()) if word_freq else 1

    # TF score
    tf_score = sum(word_freq[t] / max_freq for t in tokens) / len(tokens)

    # Position score — first and last sentences get a boost
    if position == 0:
        pos_score = 0.3
    elif position <= 1:
        pos_score = 0.2
    elif position >= total - 1:
        pos_score = 0.15
    else:
        pos_score = 0.05

    # Emergency keyword boost
    emergency_count = sum(1 for t in tokens if t in EMERGENCY_BOOST_WORDS)
    emergency_boost = min(emergency_count * 0.2, 0.6)

    # Length normalization — prefer medium-length sentences
    word_count = len(tokens)
    if word_count < 5:
        length_penalty = -0.1
    elif word_count > 30:
        length_penalty = -0.05
    else:
        length_penalty = 0.0

    return tf_score + pos_score + emergency_boost + length_penalty


def summarize_message(
    text: str,
    max_sentences: int = 3,
    min_text_length: int = 100,
) -> dict:
    """
    Summarize a message using extractive summarization.

    Args:
        text: The text to summarize.
        max_sentences: Maximum number of sentences in summary.
        min_text_length: Minimum text length to trigger summarization.

    Returns:
        dict with keys: summary, original_length, summary_length,
                       compression_ratio, sentences
    """
    if not text or len(text) < min_text_length:
        return {
            "summary": text or "",
            "original_length": len(text) if text else 0,
            "summary_length": len(text) if text else 0,
            "compression_ratio": 1.0,
            "sentences": [],
        }

    sentences = _split_sentences(text)
    if len(sentences) <= max_sentences:
        return {
            "summary": text,
            "original_length": len(text),
            "summary_length": len(text),
            "compression_ratio": 1.0,
            "sentences": sentences,
        }

    word_freq = _compute_word_freq(sentences)

    scored = []
    for i, sent in enumerate(sentences):
        score = _score_sentence(sent, word_freq, i, len(sentences))
        scored.append((i, sent, score))

    # Sort by score, take top N
    scored.sort(key=lambda x: x[2], reverse=True)
    top = scored[:max_sentences]

    # Re-order by original position
    top.sort(key=lambda x: x[0])

    summary = ". ".join(t[1] for t in top) + "."
    return {
        "summary": summary,
        "original_length": len(text),
        "summary_length": len(summary),
        "compression_ratio": round(len(summary) / len(text), 2),
        "sentences": [t[1] for t in top],
    }
