package alquran.duidev.com

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import android.widget.RemoteViews
import android.content.SharedPreferences
import es.antonborri.home_widget.HomeWidgetProvider

class PrayerWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        Log.d("PrayerWidgetProvider", "onUpdate ids=${appWidgetIds.size}")
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId, widgetData)
        }
    }

    companion object {
        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int,
            widgetData: SharedPreferences,
        ) {
            val views = RemoteViews(context.packageName, R.layout.prayer_widget)
            val location = widgetData.getString("location", "") ?: ""
            val hijri = widgetData.getString("hijriDate", "") ?: ""
            val nextName = widgetData.getString("closestPrayer", "") ?: ""
            val nextTime = widgetData.getString("closestTime", "") ?: ""
            views.setTextViewText(R.id.tv_location, location)
            views.setTextViewText(R.id.tv_hijri, hijri)
            views.setTextViewText(R.id.tv_next_name, nextName)
            views.setTextViewText(R.id.tv_next_time, nextTime)

            views.setTextViewText(R.id.tv_fajr, widgetData.getString("Fajr", "--:--") ?: "--:--")
            views.setTextViewText(R.id.tv_dhuhr, widgetData.getString("Dhuhr", "--:--") ?: "--:--")
            views.setTextViewText(R.id.tv_asr, widgetData.getString("Asr", "--:--") ?: "--:--")
            views.setTextViewText(R.id.tv_maghrib, widgetData.getString("Maghrib", "--:--") ?: "--:--")
            views.setTextViewText(R.id.tv_isha, widgetData.getString("Isha", "--:--") ?: "--:--")

            Log.d(
                "PrayerWidgetProvider",
                "update widgetId=$appWidgetId location='$location' next='$nextName $nextTime'",
            )

            val intent = Intent(context, MainActivity::class.java)
            val flags =
                PendingIntent.FLAG_UPDATE_CURRENT or if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0
            val pendingIntent = PendingIntent.getActivity(context, 0, intent, flags)
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
