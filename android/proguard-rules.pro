# Flutter-specific rules.
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugins.** { *; }

# Aturan untuk flutter_local_notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# Aturan untuk dependensi timezone yang digunakan oleh notifikasi
-keep class org.threeten.bp.** { *; }
-keep class org.joda.time.** { *; }

# --- TAMBAHKAN ATURAN BARU DI SINI ---
# Aturan untuk Google Play Core Library yang dibutuhkan oleh Flutter
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }