package com.aurelix.smartspend.smart_spend_flutter

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.os.Build
import android.util.SizeF
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class DebtsWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        val totalLent = widgetData.getString("debts_total_lent", "₹0") ?: "₹0"
        val totalBorrowed = widgetData.getString("debts_total_borrowed", "₹0") ?: "₹0"
        val netBalance = widgetData.getString("debts_net_balance", "₹0") ?: "₹0"
        val activeCount = widgetData.getString("debts_active_count", "0 active") ?: "0 active"

        // Body tap opens Debts tab in main app
        val debtsIntent = HomeWidgetLaunchIntent.getActivity(
            context,
            MainActivity::class.java,
            Uri.parse("smartspend://debts")
        )

        // Fast actions launch transparent overlay without opening main app!
        val lentIntent = Intent(context, QuickAddActivity::class.java).apply {
            action = Intent.ACTION_VIEW
            data = Uri.parse("smartspend://quick-add-debt?type=LENT")
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val lentPendingIntent = PendingIntent.getActivity(
            context,
            201,
            lentIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val borrowedIntent = Intent(context, QuickAddActivity::class.java).apply {
            action = Intent.ACTION_VIEW
            data = Uri.parse("smartspend://quick-add-debt?type=BORROWED")
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val borrowedPendingIntent = PendingIntent.getActivity(
            context,
            202,
            borrowedIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        appWidgetIds.forEach { widgetId ->
            fun setupViews(layoutId: Int, isCompact: Boolean = false): RemoteViews {
                return RemoteViews(context.packageName, layoutId).apply {
                    setTextViewText(R.id.widget_net_text, netBalance)
                    if (isCompact) {
                        setTextViewText(R.id.widget_lent_text, "Get: $totalLent")
                        setTextViewText(R.id.widget_borrowed_text, "Give: $totalBorrowed")
                    } else {
                        setTextViewText(R.id.widget_lent_text, totalLent)
                        setTextViewText(R.id.widget_borrowed_text, totalBorrowed)
                        setTextViewText(R.id.widget_active_count, activeCount)
                    }

                    setOnClickPendingIntent(R.id.widget_debts_root, debtsIntent)
                    setOnClickPendingIntent(R.id.btn_add_debt_lent, lentPendingIntent)
                    setOnClickPendingIntent(R.id.btn_add_debt_borrowed, borrowedPendingIntent)
                }
            }

            val expandedViews = setupViews(R.layout.widget_debts, isCompact = false)

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                val compactViews = setupViews(R.layout.widget_debts_compact, isCompact = true)
                val viewMapping = mapOf(
                    SizeF(100f, 50f) to compactViews,
                    SizeF(220f, 100f) to expandedViews
                )
                appWidgetManager.updateAppWidget(widgetId, RemoteViews(viewMapping))
            } else {
                appWidgetManager.updateAppWidget(widgetId, expandedViews)
            }
        }
    }
}
