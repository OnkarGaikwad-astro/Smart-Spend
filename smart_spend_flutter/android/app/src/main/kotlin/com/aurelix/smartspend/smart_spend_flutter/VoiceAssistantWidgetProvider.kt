package com.aurelix.smartspend.smart_spend_flutter

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class VoiceAssistantWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        // Fast 1-tap action launches QuickAddActivity with transparent overlay WITHOUT opening main app!
        val voiceIntent = Intent(context, QuickAddActivity::class.java).apply {
            action = Intent.ACTION_VIEW
            data = Uri.parse("smartspend://quick-voice")
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val voicePendingIntent = PendingIntent.getActivity(
            context,
            301,
            voiceIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_voice_assistant).apply {
                setOnClickPendingIntent(R.id.widget_voice_root, voicePendingIntent)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
