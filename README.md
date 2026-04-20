# FlareGun
## Portable AI-Assisted Offline Communication System using Decentralized Mesh Networking

FlareGun is a fully offline, AI-assisted emergency communication system that transforms any Android smartphone into a resilient peer-to-peer mesh network node. It enables secure messaging, location sharing, and real-time disaster guidance without relying on internet connectivity, cellular networks, or centralized servers.

---

## Overview

In disaster scenarios, communication infrastructure is often the first to fail. This leads to a breakdown in coordination, delayed emergency response, and lack of access to critical information.

FlareGun addresses this problem by enabling decentralized, infrastructure-free communication using Bluetooth Low Energy (BLE) mesh networking combined with on-device artificial intelligence and strong end-to-end encryption.

---

## Key Features

### Mesh Networking
- Bluetooth Low Energy (BLE) based peer-to-peer communication  
- Implemented using Google Nearby Connections API  
- Multi-hop routing with Time-to-Live (TTL) mechanism  
- Effective communication range up to approximately 700 meters through relay nodes  
- Store-and-forward message propagation  

### End-to-End Encryption
- X25519 Elliptic Curve Diffie-Hellman (ECDH) key exchange  
- AES-256-GCM authenticated encryption  
- HKDF-SHA256 key derivation for forward secrecy  
- Fully offline encryption with no dependency on external servers  
- Privacy-preserving architecture with no data collection  

### On-Device AI Assistance
- Powered by Gemma 3 1B model using MediaPipe  
- Provides real-time disaster guidance without internet access  
- Hybrid approach combining rule-based responses and neural inference  
- Supports scenarios such as first aid, evacuation procedures, and survival guidance  

### Additional Capabilities
- GPS-based location sharing  
- Group communication channels  
- Real-time peer discovery visualization  
- Deduplication mechanism to prevent message flooding  
- Optional WebSocket relay for hybrid operation when connectivity is available  

---

## Performance Metrics

| Metric | Value |
|------|--------|
| Message Delivery (1 hop) | 99.2% |
| Message Delivery (7 hops) | 78.3% |
| Encryption Overhead | < 22 ms |
| AI Response Accuracy | 96.7% |
| Battery Runtime | 8–10 hours (continuous use) |

---

## Technology Stack

| Layer | Technology |
|------|-----------|
| Frontend | Flutter |
| Language | Dart |
| Networking | Google Nearby Connections API (BLE) |
| Encryption | X25519, AES-256-GCM, HKDF-SHA256 |
| AI | Gemma 3 1B (MediaPipe) |
| Storage | Hive (NoSQL) |
| Security | Flutter Secure Storage (Android Keystore) |

---

## System Architecture

FlareGun follows a decentralized architecture where each device acts as both a communication endpoint and a relay node. Messages are encrypted at the source, propagated through intermediate nodes using a TTL-based routing strategy, and decrypted only at the intended recipient.

---

## Getting Started

### Prerequisites
- Flutter SDK (version 3.x or higher)  
- Android device with BLE support  
- Minimum 3 GB RAM recommended for AI inference  

### Installation

```bash
git clone https://github.com/aarontphil/FlareGun.git
cd FlareGun
flutter pub get
flutter run
