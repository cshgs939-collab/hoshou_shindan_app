package com.example.hoshou_shindan_app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class MamoruHomeWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.mamoru_widget).apply {
                val pendingIntent =
                    HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)
                setOnClickPendingIntent(R.id.widget_container, pendingIntent)
                setTextViewText(
                    R.id.gap_label,
                    widgetData.getString("gap_label", "未診断")
                )
                setTextViewText(
                    R.id.gap_value,
                    widgetData.getString("gap_value", "-")
                )
                setTextViewText(
                    R.id.updated_at,
                    widgetData.getString("updated_at", "")
                )
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
