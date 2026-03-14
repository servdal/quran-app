package alquran.duidev.com

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.os.Build
import android.widget.RemoteViews

class PrayerWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    companion object {
        private const val PREFS = "HomeWidgetPreferences"

        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int,
        ) {
            val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

            val views = RemoteViews(context.packageName, R.layout.prayer_widget)
            views.setTextViewText(R.id.tv_location, prefs.getString("location", "") ?: "")
            views.setTextViewText(R.id.tv_hijri, prefs.getString("hijriDate", "") ?: "")
            views.setTextViewText(R.id.tv_next_name, prefs.getString("closestPrayer", "") ?: "")
            views.setTextViewText(R.id.tv_next_time, prefs.getString("closestTime", "") ?: "")

            views.setTextViewText(R.id.tv_fajr, prefs.getString("Fajr", "--:--") ?: "--:--")
            views.setTextViewText(R.id.tv_dhuhr, prefs.getString("Dhuhr", "--:--") ?: "--:--")
            views.setTextViewText(R.id.tv_asr, prefs.getString("Asr", "--:--") ?: "--:--")
            views.setTextViewText(R.id.tv_maghrib, prefs.getString("Maghrib", "--:--") ?: "--:--")
            views.setTextViewText(R.id.tv_isha, prefs.getString("Isha", "--:--") ?: "--:--")

            val intent = Intent(context, MainActivity::class.java)
            val flags =
                PendingIntent.FLAG_UPDATE_CURRENT or if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0
            val pendingIntent = PendingIntent.getActivity(context, 0, intent, flags)
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}

