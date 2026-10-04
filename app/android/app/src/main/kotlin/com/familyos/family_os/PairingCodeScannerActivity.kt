package com.familyos.family_os

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.Preview
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.view.PreviewView
import androidx.core.content.ContextCompat
import com.google.mlkit.vision.barcode.BarcodeScanner
import com.google.mlkit.vision.barcode.BarcodeScanning
import com.google.mlkit.vision.barcode.common.Barcode
import com.google.mlkit.vision.common.InputImage
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

/** Camera-backed scanner for a one-time pairing QR capability. */
class PairingCodeScannerActivity : ComponentActivity() {
    private val cameraExecutor: ExecutorService = Executors.newSingleThreadExecutor()
    private lateinit var previewView: PreviewView
    private var cameraProvider: ProcessCameraProvider? = null
    private var barcodeScanner: BarcodeScanner? = null
    private var completed = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        previewView = PreviewView(this).apply {
            contentDescription = intent.getStringExtra(EXTRA_CONTENT_DESCRIPTION).orEmpty()
        }
        setContentView(previewView)
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED) {
            startCamera()
        } else {
            requestPermissions(arrayOf(Manifest.permission.CAMERA), REQUEST_CAMERA)
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == REQUEST_CAMERA &&
            ContextCompat.checkSelfPermission(this, Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED) {
            startCamera()
        } else if (requestCode == REQUEST_CAMERA) {
            finishWithoutPairingCode()
        }
    }

    private fun startCamera() {
        val future = ProcessCameraProvider.getInstance(this)
        future.addListener({
            try {
                val provider = future.get()
                cameraProvider = provider
                val preview = Preview.Builder().build().also {
                    it.surfaceProvider = previewView.surfaceProvider
                }
                val analysis = ImageAnalysis.Builder()
                    .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
                    .build()
                val scanner = BarcodeScanning.getClient()
                barcodeScanner = scanner
                analysis.setAnalyzer(cameraExecutor) { imageProxy ->
                    val mediaImage = imageProxy.image
                    if (mediaImage == null || completed) {
                        imageProxy.close()
                        return@setAnalyzer
                    }
                    scanner.process(InputImage.fromMediaImage(mediaImage, imageProxy.imageInfo.rotationDegrees))
                        .addOnSuccessListener { barcodes ->
                            val rawCode = barcodes
                                .firstOrNull { it.format == Barcode.FORMAT_QR_CODE }
                                ?.rawValue
                                ?.trim()
                            if (rawCode != null && PAIRING_CODE_PATTERN.matches(rawCode)) {
                                complete(rawCode)
                            }
                        }
                        .addOnCompleteListener { imageProxy.close() }
                }
                provider.unbindAll()
                provider.bindToLifecycle(this, CameraSelector.DEFAULT_BACK_CAMERA, preview, analysis)
            } catch (_: Exception) {
                finishWithoutPairingCode()
            }
        }, ContextCompat.getMainExecutor(this))
    }

    private fun complete(pairingCode: String) {
        if (completed || isFinishing) return
        completed = true
        setResult(RESULT_OK, Intent().putExtra(EXTRA_PAIRING_CODE, pairingCode))
        finish()
    }

    private fun finishWithoutPairingCode() {
        if (completed || isFinishing) return
        completed = true
        setResult(RESULT_CANCELED)
        finish()
    }

    override fun onDestroy() {
        cameraProvider?.unbindAll()
        barcodeScanner?.close()
        cameraExecutor.shutdown()
        super.onDestroy()
    }

    companion object {
        const val EXTRA_PAIRING_CODE = "pairing_code"
        const val EXTRA_CONTENT_DESCRIPTION = "content_description"
        private const val REQUEST_CAMERA = 9101
        private val PAIRING_CODE_PATTERN = Regex("^[A-Za-z0-9_-]{32,128}$")
    }
}
