/**
 * MessageEncryption — End-to-End Encryption using AES-GCM-256.
 * Includes ECDH key pair generation for peer key exchange.
 */

/**
 * Generate an ECDH key pair for this device.
 */
export async function generateKeyPair() {
    const keyPair = await crypto.subtle.generateKey(
        { name: 'ECDH', namedCurve: 'P-256' },
        true,
        ['deriveKey']
    );
    return keyPair;
}

/**
 * Export public key as JWK for sharing with peers.
 */
export async function exportPublicKey(keyPair) {
    return await crypto.subtle.exportKey('jwk', keyPair.publicKey);
}

/**
 * Import a peer's public key from JWK.
 */
export async function importPublicKey(jwk) {
    return await crypto.subtle.importKey(
        'jwk',
        jwk,
        { name: 'ECDH', namedCurve: 'P-256' },
        true,
        []
    );
}

/**
 * Derive a shared AES-GCM key from ECDH key exchange.
 */
export async function deriveSharedKey(privateKey, peerPublicKey) {
    return await crypto.subtle.deriveKey(
        { name: 'ECDH', public: peerPublicKey },
        privateKey,
        { name: 'AES-GCM', length: 256 },
        false,
        ['encrypt', 'decrypt']
    );
}

/**
 * Encrypt a message string using AES-GCM with the shared key.
 */
export async function encryptMessage(plaintext, sharedKey) {
    const encoder = new TextEncoder();
    const data = encoder.encode(plaintext);
    const iv = crypto.getRandomValues(new Uint8Array(12));

    const encrypted = await crypto.subtle.encrypt(
        { name: 'AES-GCM', iv },
        sharedKey,
        data
    );

    return {
        ciphertext: arrayBufferToBase64(encrypted),
        iv: arrayBufferToBase64(iv.buffer),
    };
}

/**
 * Decrypt a message using AES-GCM with the shared key.
 */
export async function decryptMessage(ciphertextB64, ivB64, sharedKey) {
    const ciphertext = base64ToArrayBuffer(ciphertextB64);
    const iv = base64ToArrayBuffer(ivB64);

    const decrypted = await crypto.subtle.decrypt(
        { name: 'AES-GCM', iv },
        sharedKey,
        ciphertext
    );

    return new TextDecoder().decode(decrypted);
}

function arrayBufferToBase64(buffer) {
    const bytes = new Uint8Array(buffer);
    let binary = '';
    for (let i = 0; i < bytes.byteLength; i++) {
        binary += String.fromCharCode(bytes[i]);
    }
    return btoa(binary);
}

function base64ToArrayBuffer(base64) {
    const binary = atob(base64);
    const bytes = new Uint8Array(binary.length);
    for (let i = 0; i < binary.length; i++) {
        bytes[i] = binary.charCodeAt(i);
    }
    return bytes.buffer;
}

/**
 * Verify encryption round-trip.
 */
export async function testEncryption(sharedKey) {
    const testMessage = 'MeshLink encryption test ✓';
    const { ciphertext, iv } = await encryptMessage(testMessage, sharedKey);
    const decrypted = await decryptMessage(ciphertext, iv, sharedKey);
    return decrypted === testMessage;
}
