package alquran.duidev.com

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.SystemClock
import android.util.TypedValue
import android.util.Log
import android.widget.RemoteViews
import android.content.SharedPreferences
import android.graphics.Color
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
            val closestEpoch = widgetData.getLong("closestTimeEpoch", 0L)
            views.setTextViewText(R.id.tv_location, location)
            views.setTextViewText(R.id.tv_hijri, hijri)
            views.setTextViewText(R.id.tv_to_prayer, if (nextName.isNotEmpty()) "To $nextName" else "")

            views.setTextViewText(R.id.tv_fajr, widgetData.getString("Fajr", "--:--") ?: "--:--")
            views.setTextViewText(R.id.tv_dhuhr, widgetData.getString("Dhuhr", "--:--") ?: "--:--")
            views.setTextViewText(R.id.tv_asr, widgetData.getString("Asr", "--:--") ?: "--:--")
            views.setTextViewText(R.id.tv_maghrib, widgetData.getString("Maghrib", "--:--") ?: "--:--")
            views.setTextViewText(R.id.tv_isha, widgetData.getString("Isha", "--:--") ?: "--:--")

            applyCountdown(views, closestEpoch)
            applyHighlight(views, nextName)

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

        private fun applyCountdown(views: RemoteViews, closestEpochMillis: Long) {
            if (closestEpochMillis <= 0L) {
                views.setChronometer(R.id.chron_countdown, SystemClock.elapsedRealtime(), null, false)
                return
            }
            val diff = closestEpochMillis - System.currentTimeMillis()
            if (diff <= 0L) {
                views.setChronometer(R.id.chron_countdown, SystemClock.elapsedRealtime(), null, false)
                return
            }

            val base = SystemClock.elapsedRealtime() + diff
            views.setChronometer(R.id.chron_countdown, base, "%s", true)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                views.setChronometerCountDown(R.id.chron_countdown, true)
            }
        }

        private fun applyHighlight(views: RemoteViews, nextName: String) {
            val normal = Color.WHITE
            val highlight = Color.parseColor("#FFE082")

            fun setRow(labelId: Int, timeId: Int, key: String) {
                val isNext = key.equals(nextName, ignoreCase = true)
                val c = if (isNext) highlight else normal
                val size = if (isNext) 13f else 12f
                views.setTextColor(labelId, c)
                views.setTextColor(timeId, c)
                views.setTextViewTextSize(labelId, TypedValue.COMPLEX_UNIT_SP, size)
                views.setTextViewTextSize(timeId, TypedValue.COMPLEX_UNIT_SP, size)
            }

            setRow(R.id.tv_lbl_fajr, R.id.tv_fajr, "Fajr")
            setRow(R.id.tv_lbl_dhuhr, R.id.tv_dhuhr, "Dhuhr")
            setRow(R.id.tv_lbl_asr, R.id.tv_asr, "Asr")
            setRow(R.id.tv_lbl_maghrib, R.id.tv_maghrib, "Maghrib")
            setRow(R.id.tv_lbl_isha, R.id.tv_isha, "Isha")
        }
    }
}
