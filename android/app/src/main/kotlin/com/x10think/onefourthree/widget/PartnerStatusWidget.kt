package com.x10think.onefourthree.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import android.view.View
import com.x10think.onefourthree.MainActivity
import com.x10think.onefourthree.R
import es.antonborri.home_widget.HomeWidgetPlugin

class PartnerStatusWidget : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        val prefs = HomeWidgetPlugin.getData(context)
        ids.forEach { id ->
            val views = RemoteViews(context.packageName, R.layout.partner_status_widget)
            views.setTextViewText(R.id.widget_title, prefs.getString("title", "143 · Our little world"))
            views.setTextViewText(R.id.widget_status, prefs.getString("partner_status", "Open 143 to refresh"))
            views.setTextViewText(R.id.widget_detail, prefs.getString("detail", "Private by default ♡"))
            val intent = Intent(context, MainActivity::class.java).apply {
                action = Intent.ACTION_VIEW
                data = android.net.Uri.parse("onefourthree://home")
                flags = Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
            }
            val pi = PendingIntent.getActivity(context, 143, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
            views.setOnClickPendingIntent(R.id.widget_root, pi)

            // Quick Ping never performs a network action from the widget itself.
            // It opens a confirmation surface in Flutter so the user explicitly initiates the haptic/notification interaction.
            val pingIntent = Intent(context, MainActivity::class.java).apply {
                action = Intent.ACTION_VIEW
                data = android.net.Uri.parse("onefourthree://widget/ping")
                flags = Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
            }
            val pingPi = PendingIntent.getActivity(context, 144, pingIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
            val quickPingEnabled = prefs.getBoolean("quick_ping_enabled", true)
            views.setViewVisibility(R.id.widget_ping, if (quickPingEnabled) View.VISIBLE else View.GONE)
            if (quickPingEnabled) views.setOnClickPendingIntent(R.id.widget_ping, pingPi)
            manager.updateAppWidget(id, views)
        }
    }
}
