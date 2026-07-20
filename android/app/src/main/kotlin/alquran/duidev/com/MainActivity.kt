package alquran.duidev.com

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.ryanheise.audioservice.AudioServicePlugin
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val speechControlChannel = "quran_app/android_speech_recognizer/control"
    private val speechEventChannel = "quran_app/android_speech_recognizer/events"
    private val requestRecordAudioCode = 3107
    private val mainHandler = Handler(Looper.getMainLooper())

    private var speechRecognizer: SpeechRecognizer? = null
    private var speechEvents: EventChannel.EventSink? = null
    private var isSpeechConfigured = false
    private var isSpeechListening = false
    private var speechLanguage = "ar-SA"
    private var pendingStartResult: MethodChannel.Result? = null

    override fun provideFlutterEngine(context: android.content.Context): FlutterEngine? {
        return AudioServicePlugin.getFlutterEngine(context)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, speechControlChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isAvailable" -> result.success(SpeechRecognizer.isRecognitionAvailable(this))
                    "configure" -> {
                        speechLanguage = call.argument<String>("language") ?: "ar-SA"
                        isSpeechConfigured = true
                        result.success(null)
                    }
                    "start" -> startAndroidSpeech(result)
                    "stop" -> {
                        stopAndroidSpeech()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, speechEventChannel)
            .setStreamHandler(
                object : EventChannel.StreamHandler {
                    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                        speechEvents = events
                    }

                    override fun onCancel(arguments: Any?) {
                        speechEvents = null
                    }
                },
            )
    }

    private fun startAndroidSpeech(result: MethodChannel.Result) {
        if (!SpeechRecognizer.isRecognitionAvailable(this)) {
            result.error("unavailable", "Android SpeechRecognizer tidak tersedia di perangkat ini", null)
            return
        }

        if (ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO) !=
            PackageManager.PERMISSION_GRANTED
        ) {
            if (pendingStartResult != null) {
                result.error("microphone_permission", "Permintaan izin mikrofon masih berjalan", null)
                return
            }
            pendingStartResult = result
            ActivityCompat.requestPermissions(
                this,
                arrayOf(Manifest.permission.RECORD_AUDIO),
                requestRecordAudioCode,
            )
            return
        }

        if (!isSpeechConfigured) {
            speechLanguage = "ar-SA"
            isSpeechConfigured = true
        }

        isSpeechListening = true
        ensureSpeechRecognizer()
        startSpeechListening()
        result.success(null)
    }

    private fun ensureSpeechRecognizer() {
        if (speechRecognizer != null) return

        speechRecognizer = SpeechRecognizer.createSpeechRecognizer(this).also { recognizer ->
            recognizer.setRecognitionListener(
                object : RecognitionListener {
                    override fun onReadyForSpeech(params: Bundle?) {
                        emitSpeechDebug("audio", "Mic aktif")
                    }

                    override fun onBeginningOfSpeech() {
                        emitSpeechDebug("audio", "Mulai mendengar")
                    }

                    override fun onRmsChanged(rmsdB: Float) {
                        val level = (rmsdB.coerceAtLeast(0f) / 10f).coerceIn(0f, 1f).toDouble()
                        emitSpeechResult(
                            transcript = "",
                            alternatives = emptyList(),
                            isFinal = false,
                            debugType = "audio",
                            debugMessage = "Mic aktif",
                            micLevel = level,
                            peakLevel = level,
                        )
                    }

                    override fun onBufferReceived(buffer: ByteArray?) = Unit

                    override fun onEndOfSpeech() = Unit

                    override fun onError(error: Int) {
                        if (!isSpeechListening) return

                        if (error == SpeechRecognizer.ERROR_INSUFFICIENT_PERMISSIONS ||
                            error == SpeechRecognizer.ERROR_RECOGNIZER_BUSY
                        ) {
                            emitSpeechError(speechErrorMessage(error))
                            stopAndroidSpeech()
                            return
                        }

                        emitSpeechResult(
                            transcript = "",
                            alternatives = emptyList(),
                            isFinal = true,
                            debugType = "result",
                            debugMessage = speechErrorMessage(error),
                        )
                        restartSpeechListening()
                    }

                    override fun onResults(results: Bundle?) {
                        emitRecognitionBundle(results, isFinal = true)
                        if (isSpeechListening) restartSpeechListening()
                    }

                    override fun onPartialResults(partialResults: Bundle?) {
                        emitRecognitionBundle(partialResults, isFinal = false)
                    }

                    override fun onEvent(eventType: Int, params: Bundle?) = Unit
                },
            )
        }
    }

    private fun startSpeechListening() {
        val recognizer = speechRecognizer ?: return
        val intent =
            Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
                putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
                putExtra(RecognizerIntent.EXTRA_LANGUAGE, speechLanguage)
                putExtra(RecognizerIntent.EXTRA_LANGUAGE_PREFERENCE, speechLanguage)
                putExtra(RecognizerIntent.EXTRA_ONLY_RETURN_LANGUAGE_PREFERENCE, false)
                putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
                putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 5)
                putExtra(RecognizerIntent.EXTRA_CALLING_PACKAGE, packageName)
            }
        recognizer.startListening(intent)
    }

    private fun restartSpeechListening() {
        mainHandler.postDelayed(
            {
                if (!isSpeechListening) return@postDelayed
                try {
                    speechRecognizer?.cancel()
                    startSpeechListening()
                } catch (error: Exception) {
                    emitSpeechError(error.message ?: "Android SpeechRecognizer gagal dimulai ulang")
                    stopAndroidSpeech()
                }
            },
            250L,
        )
    }

    private fun stopAndroidSpeech() {
        pendingStartResult?.error("cancelled", "Pengenalan suara dibatalkan", null)
        pendingStartResult = null
        isSpeechListening = false
        speechRecognizer?.cancel()
    }

    private fun emitRecognitionBundle(results: Bundle?, isFinal: Boolean) {
        val matches =
            results
                ?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                ?.filter { it.isNotBlank() }
                ?: emptyList()
        val transcript = matches.firstOrNull().orEmpty()
        emitSpeechResult(
            transcript = transcript,
            alternatives = matches,
            isFinal = isFinal,
            debugType = "result",
            debugMessage = "",
            confidence = if (transcript.isBlank()) 0.0 else 1.0,
        )
    }

    private fun emitSpeechDebug(type: String, message: String) {
        emitSpeechResult(
            transcript = "",
            alternatives = emptyList(),
            isFinal = false,
            debugType = type,
            debugMessage = message,
        )
    }

    private fun emitSpeechError(message: String) {
        emitSpeechResult(
            transcript = "",
            alternatives = emptyList(),
            isFinal = true,
            debugType = "error",
            debugMessage = message,
        )
    }

    private fun emitSpeechResult(
        transcript: String,
        alternatives: List<String>,
        isFinal: Boolean,
        debugType: String,
        debugMessage: String,
        confidence: Double = 0.0,
        micLevel: Double = 0.0,
        peakLevel: Double = 0.0,
    ) {
        mainHandler.post {
            speechEvents?.success(
                mapOf(
                    "transcript" to transcript,
                    "phonemes" to transcript,
                    "alternatives" to alternatives,
                    "confidence" to confidence,
                    "isFinal" to isFinal,
                    "debugType" to debugType,
                    "debugMessage" to debugMessage,
                    "micLevel" to micLevel,
                    "peakLevel" to peakLevel,
                    "audioSamples" to 0,
                ),
            )
        }
    }

    private fun speechErrorMessage(error: Int): String {
        return when (error) {
            SpeechRecognizer.ERROR_AUDIO -> "Masalah audio mikrofon"
            SpeechRecognizer.ERROR_CLIENT -> "SpeechRecognizer dihentikan"
            SpeechRecognizer.ERROR_INSUFFICIENT_PERMISSIONS -> "Izin mikrofon belum diberikan"
            SpeechRecognizer.ERROR_NETWORK -> "Jaringan bermasalah saat pengenalan suara"
            SpeechRecognizer.ERROR_NETWORK_TIMEOUT -> "Koneksi pengenalan suara timeout"
            SpeechRecognizer.ERROR_NO_MATCH -> "Tidak ada ucapan yang cocok"
            SpeechRecognizer.ERROR_RECOGNIZER_BUSY -> "SpeechRecognizer masih sibuk"
            SpeechRecognizer.ERROR_SERVER -> "Layanan pengenalan suara bermasalah"
            SpeechRecognizer.ERROR_SPEECH_TIMEOUT -> "Tidak ada suara terdeteksi"
            else -> "SpeechRecognizer error $error"
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != requestRecordAudioCode) return
        val pendingResult = pendingStartResult
        pendingStartResult = null
        if (grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED && pendingResult != null) {
            isSpeechListening = true
            ensureSpeechRecognizer()
            startSpeechListening()
            pendingResult.success(null)
        } else {
            emitSpeechError("Izin mikrofon belum diberikan")
            pendingResult?.error("microphone_permission", "Izin mikrofon belum diberikan", null)
        }
    }

    override fun onDestroy() {
        stopAndroidSpeech()
        speechRecognizer?.destroy()
        speechRecognizer = null
        super.onDestroy()
    }
}
