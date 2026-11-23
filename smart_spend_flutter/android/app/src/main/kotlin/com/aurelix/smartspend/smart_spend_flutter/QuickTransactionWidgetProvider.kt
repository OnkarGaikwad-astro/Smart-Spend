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

class QuickTransactionWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        val totalBalance = widgetData.getString("total_balance", "₹0") ?: "₹0"
        val monthlyExpense = widgetData.getString("monthly_expense", "₹0") ?: "₹0"

        // Clicking widget body opens Dashboard in main app
        val appIntent = HomeWidgetLaunchIntent.getActivity(
            context,
            MainActivity::class.java,
            Uri.parse("smartspend://dashboard")
        )

        // Clicking + Add Expense launches QuickAddActivity as a transparent floating overlay WITHOUT opening the main app!
        val quickAddIntent = Intent(context, QuickAddActivity::class.java).apply {
            action = Intent.ACTION_VIEW
            data = Uri.parse("smartspend://quick-add?type=EXPENSE")
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val quickAddPendingIntent = PendingIntent.getActivity(
            context,
            101,
            quickAddIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        appWidgetIds.forEach { widgetId ->
            fun setupViews(layoutId: Int, isCompact: Boolean = false): RemoteViews {
                return RemoteViews(context.packageName, layoutId).apply {
                    setTextViewText(R.id.widget_balance_text, totalBalance)
                    setTextViewText(R.id.widget_expense_text, monthlyExpense)

                    setOnClickPendingIntent(R.id.widget_quick_root, appIntent)
                    setOnClickPendingIntent(R.id.btn_add_expense, quickAddPendingIntent)
                }
            }

            val expandedViews = setupViews(R.layout.widget_quick_transaction, isCompact = false)

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                val compactViews = setupViews(R.layout.widget_quick_transaction_compact, isCompact = true)
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
