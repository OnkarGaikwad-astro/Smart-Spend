package com.aurelix.smartspend.smart_spend_flutter

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.FlutterActivityLaunchConfigs.BackgroundMode

class QuickAddActivity : FlutterActivity() {
    override fun getBackgroundMode(): BackgroundMode {
        return BackgroundMode.transparent
    }

    override fun getInitialRoute(): String {
        val uri = intent?.data
        return if (uri != null) {
            val host = uri.host ?: "quick-add"
            val type = uri.getQueryParameter("type") ?: "EXPENSE"
            "/$host?type=$type"
        } else {
            "/quick-add?type=EXPENSE"
        }
    }
}
