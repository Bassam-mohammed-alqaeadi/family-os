package com.familyos.family_os

import android.app.Activity
import android.graphics.Bitmap
import android.graphics.Color
import android.os.Bundle
import android.view.Gravity
import android.widget.Button
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import com.google.zxing.BarcodeFormat
import com.google.zxing.qrcode.QRCodeWriter

/** Shows the one-time pairing capability as a real QR code without persisting it. */
class PairingCodeQrActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val code = intent.getStringExtra(EXTRA_PAIRING_CODE)
        if (code == null || !PAIRING_CODE_PATTERN.matches(code)) {
            finish()
            return
        }
        val density = resources.displayMetrics.density
        val padding = (24 * density).toInt()
        val imageSize = (280 * density).toInt()
        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding(padding, padding, padding, padding)
        }
        val title = intent.getStringExtra(EXTRA_TITLE).orEmpty()
        if (title.isNotEmpty()) {
            root.addView(TextView(this).apply {
                text = title
                textSize = 20f
                gravity = Gravity.CENTER
            })
        }
        val body = intent.getStringExtra(EXTRA_BODY).orEmpty()
        if (body.isNotEmpty()) {
            root.addView(TextView(this).apply {
                text = body
                textSize = 15f
                gravity = Gravity.CENTER
                setPadding(0, (12 * density).toInt(), 0, (12 * density).toInt())
            })
        }
        root.addView(ImageView(this).apply {
            contentDescription = intent.getStringExtra(EXTRA_CONTENT_DESCRIPTION).orEmpty()
            setImageBitmap(toBitmap(code, imageSize))
        }, LinearLayout.LayoutParams(imageSize, imageSize))
        root.addView(TextView(this).apply {
            text = code
            textSize = 14f
            gravity = Gravity.CENTER
            setPadding(0, (16 * density).toInt(), 0, (12 * density).toInt())
        })
        root.addView(Button(this).apply {
            text = intent.getStringExtra(EXTRA_DISMISS_LABEL).orEmpty().ifBlank { "×" }
            setOnClickListener { finish() }
        })
        setContentView(root)
    }

    private fun toBitmap(value: String, size: Int): Bitmap {
        val matrix = QRCodeWriter().encode(value, BarcodeFormat.QR_CODE, size, size)
        val pixels = IntArray(size * size) { index ->
            if (matrix[index % size, index / size]) Color.BLACK else Color.WHITE
        }
        return Bitmap.createBitmap(pixels, size, size, Bitmap.Config.ARGB_8888)
    }

    companion object {
        const val EXTRA_PAIRING_CODE = "pairing_code"
        const val EXTRA_TITLE = "title"
        const val EXTRA_BODY = "body"
        const val EXTRA_CONTENT_DESCRIPTION = "content_description"
        const val EXTRA_DISMISS_LABEL = "dismiss_label"
        private val PAIRING_CODE_PATTERN = Regex("^[A-Za-z0-9_-]{32,128}$")
    }
}
