package com.airwatch.mobile

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

/**
 * Home-screen widget surfacing the latest live-flight summary.
 *
 * Reads four keys (live_flights, top_airline_icao, top_airline_count,
 * updated_at) from the SharedPreferences store managed by the
 * `home_widget` Flutter plugin and renders them via the layout
 * `flight_widget.xml`.
 *
 * The Flutter side calls `HomeWidget.updateWidget(name = …)` after
 * every poll tick; that fires an `ACTION_APPWIDGET_UPDATE` intent at
 * this provider, which is when [onUpdate] runs.
 */
class FlightWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val prefs = HomeWidgetPlugin.getData(context)
        val live = prefs.getInt("live_flights", 0)
        val airline = prefs.getString("top_airline_icao", null) ?: "—"
        val airlineCount = prefs.getInt("top_airline_count", 0)
        val updated = prefs.getString("updated_at", null)

        val views = RemoteViews(context.packageName, R.layout.flight_widget)
        views.setTextViewText(R.id.tv_live_count, live.toString())
        views.setTextViewText(R.id.tv_top_airline, airline)
        views.setTextViewText(
            R.id.tv_top_airline_count,
            if (airlineCount == 0) "" else "$airlineCount flights"
        )
        views.setTextViewText(
            R.id.tv_updated,
            updated?.let { iso ->
                // iso looks like 2025-01-01T12:34:56.789 — show only HH:mm
                // so the line stays compact in the widget grid.
                val t = iso.substringAfter('T').substringBefore('.')
                if (t.length >= 5) "Updated ${t.substring(0, 5)}" else "Updated"
            } ?: "—"
        )

        // Tapping the widget opens the app at the map screen.
        val launchIntent = context.packageManager
            .getLaunchIntentForPackage(context.packageName)
            ?.apply { addFlags(Intent.FLAG_ACTIVITY_NEW_TASK) }
        if (launchIntent != null) {
            val pi = android.app.PendingIntent.getActivity(
                context,
                0,
                launchIntent,
                android.app.PendingIntent.FLAG_IMMUTABLE
                    or android.app.PendingIntent.FLAG_UPDATE_CURRENT,
            )
            views.setOnClickPendingIntent(R.id.widget_root, pi)
        }

        for (id in appWidgetIds) {
            appWidgetManager.updateAppWidget(id, views)
        }
    }
}
