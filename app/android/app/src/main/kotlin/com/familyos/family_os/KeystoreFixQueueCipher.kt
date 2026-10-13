package com.familyos.family_os

import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import java.nio.ByteBuffer
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

/**
 * S2 resilience: the production [FixQueueCipher], backed by a non-exportable Android
 * Keystore key (AES-256-GCM, random IV per write).
 *
 * NOTE(Android-only): this file imports `android.*` and must NOT be added to
 * `tools/android/run_native_protocol_tests.sh` SOURCES. It is intentionally a thin twin
 * of the key handling in `TelemetryConfigStore` (same transformation, same IV framing,
 * its own key alias): the queue it protects is fully tested on the plain JVM with a
 * fake cipher, and this class contributes no logic beyond "the platform's key".
 *
 * Before first unlock (direct boot) the Keystore key is unavailable and every call
 * throws - which is exactly why the boot receiver records only a marker pre-unlock and
 * does the real work after `USER_UNLOCKED` (D3). The store turns that into counted load
 * failures, never a crash.
 */
class KeystoreFixQueueCipher : FixQueueCipher {
    override fun encrypt(plain: ByteArray): ByteArray {
        val cipher = Cipher.getInstance(TRANSFORMATION)
        cipher.init(Cipher.ENCRYPT_MODE, key())
        val encrypted = cipher.doFinal(plain)
        return ByteBuffer.allocate(4 + cipher.iv.size + encrypted.size)
            .putInt(cipher.iv.size)
            .put(cipher.iv)
            .put(encrypted)
            .array()
    }

    override fun decrypt(blob: ByteArray): ByteArray {
        val buffer = ByteBuffer.wrap(blob)
        val ivLength = buffer.int
        require(ivLength in 12..32 && buffer.remaining() > ivLength) { "queue blob framing invalid" }
        val iv = ByteArray(ivLength)
        buffer.get(iv)
        val encrypted = ByteArray(buffer.remaining())
        buffer.get(encrypted)
        val cipher = Cipher.getInstance(TRANSFORMATION)
        cipher.init(Cipher.DECRYPT_MODE, key(), GCMParameterSpec(128, iv))
        return cipher.doFinal(encrypted)
    }

    private fun key(): SecretKey {
        val store = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
        (store.getKey(KEY_ALIAS, null) as? SecretKey)?.let { return it }
        val generator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore")
        generator.init(
            KeyGenParameterSpec.Builder(KEY_ALIAS, KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT)
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                .setKeySize(256)
                .build(),
        )
        return generator.generateKey()
    }

    companion object {
        private const val KEY_ALIAS = "family_os_fix_queue_v1"
        private const val TRANSFORMATION = "AES/GCM/NoPadding"
    }
}
