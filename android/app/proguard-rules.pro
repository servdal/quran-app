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

# Menjaga file native just_audio agar tidak di-minify
-keep class com.ryanheise.just_audio.** { *; }

# Menjaga kelas audio_service
-keep class com.ryanheise.audioservice.** { *; }

# Jika Anda menggunakan AndroidX media (diperlukan oleh audio_service terbaru)
-keep class androidx.media.** { *; }

# =====================================================================
# ATURAN PROGUARD UNTUK VOSK DAN JNA (ANTI-CRASH PEER FIELD ID)
# =====================================================================

# 1. Jaga agar struktur internal JNA tidak di-obfuscate atau dihapus
-keep class com.sun.jna.** { *; }
-keep class * implements com.sun.jna.** { *; }
-dontwarn com.sun.jna.**

# Sangat Krusial: Cegah modifikasi field 'peer' yang dicari oleh JNI
-keepclassmembers class com.sun.jna.Pointer {
    private long peer;
}

# 2. Jaga agar Vosk SDK tidak diacak strukturnya
-keep class org.vosk.** { *; }
-dontwarn org.vosk.**

# 3. Jaga agar library native .so tidak dilepas saat runtime optimization
-keepattributes Signature,InnerClasses,EnclosingMethod,AnnotationDefault,*Annotation*,EnclosingMethod

# =====================================================================
# MENGATASI MISSING CLASSES PLAY CORE PADA RELEASES FLUTTER DEFERRED COMPONENTS
# =====================================================================

-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**