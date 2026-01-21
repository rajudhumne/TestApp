# Security Considerations

## Identified risks
- Plaintext passwords: `LoginView` compares stored `passwordHash` directly to user input, and `UserRepository` persists the same value without hashing or salting. Compromise of the SQLite file exposes credentials.
- Local SQLite exposure: The database is stored in the user’s Documents directory without OS-level protection (no File Protection, no encryption). Malware or another user on the machine can read user identities and records.
- Network/AI calls without TLS: `OllamaEndpoint` defaults to `http://localhost:11434`; if this is re-pointed or accessed remotely, prompts and responses can traverse the network unencrypted, allowing interception or tampering.
- Push notification data handling: `AppDelegate` forwards `userInfo` from push notifications directly to the app via `NotificationCenter` without validation. Malformed or unexpected payloads could drive unsafe app behavior if later trusted.

## Recommended mitigations
- Hash and salt passwords using a modern KDF (Argon2id/scrypt/BCrypt) and compare hashes, not plaintext.
- Protect SQLite data at rest: move to an app sandbox path, enable file protection (where available), and/or add application-layer encryption for sensitive tables.
- Enforce TLS for all network endpoints and validate certificates; keep Ollama behind localhost or secure the endpoint with mTLS/auth.
- Validate and schema-check push payloads before use; ignore unexpected keys and add logging/alerts for invalid payloads.

