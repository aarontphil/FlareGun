/**
 * KeyManager — Identity and key management using the Web Crypto API.
 * Handles ECDH P-256 keypair generation, public key exchange,
 * and shared secret derivation for end-to-end encryption.
 */

/**
 * Generate an ECDH P-256 keypair for a node's identity.
 * @returns {{ publicKey: CryptoKey, privateKey: CryptoKey }}
 */
export async function generateKeyPair() {
    const keyPair = await crypto.subtle.generateKey(
        { name: 'ECDH', namedCurve: 'P-256' },
        true,  // extractable (so we can export public key)
        ['deriveKey', 'deriveBits']
    );
    return keyPair;
}

/**
 * Export a public key to a transmittable JWK format.
 */
export async function exportPublicKey(publicKey) {
    return await crypto.subtle.exportKey('jwk', publicKey);
}

/**
 * Import a public key from JWK format.
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
 * Derive a shared AES-GCM-256 key from our private key and their public key.
 * This is the ECDH Diffie-Hellman key agreement.
 */
export async function deriveSharedKey(privateKey, peerPublicKey) {
    return await crypto.subtle.deriveKey(
        { name: 'ECDH', public: peerPublicKey },
        privateKey,
        { name: 'AES-GCM', length: 256 },
        false,  // not extractable
        ['encrypt', 'decrypt']
    );
}

/**
 * Generate a keypair and export the public key for a node.
 * Returns the full identity object.
 */
export async function createNodeIdentity() {
    const { publicKey, privateKey } = await generateKeyPair();
    const publicKeyJwk = await exportPublicKey(publicKey);
    return {
        publicKey,
        privateKey,
        publicKeyJwk,
    };
}

/**
 * Establish a shared key between two nodes.
 * Each node calls this with their private key and the other's public key.
 */
export async function establishSharedKey(myPrivateKey, peerPublicKeyJwk) {
    const peerPublicKey = await importPublicKey(peerPublicKeyJwk);
    return await deriveSharedKey(myPrivateKey, peerPublicKey);
}
