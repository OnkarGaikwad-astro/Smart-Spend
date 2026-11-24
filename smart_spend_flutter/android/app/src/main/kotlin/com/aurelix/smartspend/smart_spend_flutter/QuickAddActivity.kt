package com.aurelix.smartspend.smart_spend_flutter

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.FlutterActivityLaunchConfigs.BackgroundMode

class QuickAddActivity : FlutterActivity() {
    override fun getBackgroundMode(): BackgroundMode {
        return BackgroundMode.transparent
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
    }

    override fun getInitialRoute(): String {
        val uri = intent?.data
        return if (uri != null) {
            val host = uri.host ?: "quick-add"
            val type = uri.getQueryParameter("type") ?: "EXPENSE"
            if (host == "quick-voice" || host == "voice-assistant") {
                "/quick-voice"
            } else {
                "/$host?type=$type"
            }
        } else {
            "/quick-add?type=EXPENSE"
        }
    }
}
