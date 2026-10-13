package com.familyos.family_os

/**
 * S2 resilience: byte-level encryption for the persisted offline queue.
 *
 * Android-free interface so `EncryptedFixQueueStore` stays provable by plain JVM tests
 * with a fake cipher. The production implementation is [KeystoreFixQueueCipher] (Android
 * Keystore, AES-256-GCM); tests use an in-memory fake and never touch the Keystore.
 *
 * The blob format is the implementation's own contract (IV-prefixed GCM in production):
 * callers treat blobs as opaque. Any failure throws - the store counts it and keeps
 * serving from memory rather than crashing the service.
 */
interface FixQueueCipher {
    /** Encrypts [plain]; the returned blob carries everything [decrypt] needs. */
    @Throws(Exception::class)
    fun encrypt(plain: ByteArray): ByteArray

    /** Decrypts a blob from [encrypt]; throws on any tampering or key problem. */
    @Throws(Exception::class)
    fun decrypt(blob: ByteArray): ByteArray
}
