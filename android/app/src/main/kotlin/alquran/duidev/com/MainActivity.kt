package alquran.duidev.com

import android.Manifest
import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.io.File
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import org.json.JSONArray
import org.json.JSONObject
import org.vosk.Model
import org.vosk.Recognizer
import org.vosk.android.RecognitionListener
import org.vosk.android.SpeechService

class MainActivity : FlutterActivity(), RecognitionListener {
    private val controlChannelName = "quran_app/offline_recitation/control"
    private val eventChannelName = "quran_app/offline_recitation/events"

    private var eventSink: EventChannel.EventSink? = null
    private var model: Model? = null
    private var recognizer: Recognizer? = null
    private var speechService: SpeechService? = null
    private var modelPath: String? = null
    private var modelId: String? = null
    private var grammarJson: String? = null
    private var isLoading = false
    private var pendingStartAfterPermission = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, eventChannelName)
            .setStreamHandler(
                object : EventChannel.StreamHandler {
                    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                        eventSink = events
                    }

                    override fun onCancel(arguments: Any?) {
                        eventSink = null
                    }
                },
            )

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, controlChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isAvailable" -> result.success(true)
                    "configure" -> {
                        modelId = call.argument<String>("modelId")
                        modelPath = call.argument<String>("modelPath")
                        val activeWords = call.argument<List<String>>("activeWords") ?: emptyList()
                        val expectedPhrase = call.argument<String>("expectedPhrase") ?: ""
                        grammarJson = buildGrammarJson(activeWords, expectedPhrase)
                        val path = modelPath
                        if (modelId != "vosk_arabic") {
                            result.error(
                                "UNSUPPORTED_MODEL",
                                "Android recognizer saat ini memakai Vosk Arabic. Pilih model Vosk Arabic.",
                                null,
                            )
                            return@setMethodCallHandler
                        }
                        if (path.isNullOrBlank() || !File(path).exists()) {
                            result.error("MODEL_NOT_FOUND", "Model Vosk Arabic belum ditemukan.", path)
                            return@setMethodCallHandler
                        }
                        result.success(null)
                    }
                    "start" -> startVosk(result)
                    "stop" -> {
                        stopVosk()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun startVosk(result: MethodChannel.Result) {
        val path = modelPath
        if (path.isNullOrBlank() || !File(path).exists()) {
            result.error("MODEL_NOT_FOUND", "Model Vosk Arabic belum ditemukan.", path)
            return
        }
        if (speechService != null || isLoading) {
            result.success(null)
            return
        }

        if (
            ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO) !=
                PackageManager.PERMISSION_GRANTED
        ) {
            pendingStartAfterPermission = true
            ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.RECORD_AUDIO), 9137)
            result.success(null)
            return
        }

        startVoskInternal(path)
        result.success(null)
    }

    private fun startVoskInternal(path: String) {
        if (speechService != null || isLoading) return

        isLoading = true
        Thread {
            try {
                if (model == null) {
                    model = Model(path)
                }
                recognizer =
                    if (grammarJson.isNullOrBlank()) {
                        Recognizer(model, 16000.0f)
                    } else {
                        Recognizer(model, 16000.0f, grammarJson)
                    }
                recognizer?.setWords(true)
                recognizer?.setPartialWords(true)
                recognizer?.setMaxAlternatives(3)
                speechService = SpeechService(recognizer, 16000.0f)
                runOnUiThread {
                    isLoading = false
                    speechService?.startListening(this)
                }
            } catch (error: Exception) {
                runOnUiThread {
                    isLoading = false
                    emitResult(error.message ?: "Gagal memuat model Vosk", true)
                }
            }
        }.start()
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != 9137 || !pendingStartAfterPermission) return

        pendingStartAfterPermission = false
        if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
            modelPath?.let { startVoskInternal(it) }
        } else {
            emitResult("Izin mikrofon ditolak", true)
        }
    }

    private fun stopVosk() {
        speechService?.stop()
        speechService?.shutdown()
        speechService = null
        recognizer?.close()
        recognizer = null
    }

    override fun onPartialResult(hypothesis: String?) {
        emitJson(hypothesis, false)
    }

    override fun onResult(hypothesis: String?) {
        emitJson(hypothesis, false)
    }

    override fun onFinalResult(hypothesis: String?) {
        emitJson(hypothesis, true)
        stopVosk()
    }

    override fun onError(exception: Exception?) {
        emitResult(exception?.message ?: "Pengenalan suara gagal", true)
        stopVosk()
    }

    override fun onTimeout() {
        emitResult("", true)
        stopVosk()
    }

    private fun emitJson(hypothesis: String?, isFinal: Boolean) {
        val parsed =
            try {
                JSONObject(hypothesis ?: "{}")
            } catch (_: Exception) {
                null
            }
        val text =
            parsed
                ?.optString("text")
                ?.ifEmpty { parsed.optString("partial") }
                ?: hypothesis.orEmpty()
        val alternatives = mutableListOf<String>()
        val altArray = parsed?.optJSONArray("alternatives")
        if (altArray != null) {
            for (i in 0 until altArray.length()) {
                val altText = altArray.optJSONObject(i)?.optString("text").orEmpty()
                if (altText.isNotBlank()) alternatives.add(altText)
            }
        }
        emitResult(text, isFinal, alternatives)
    }

    private fun emitResult(text: String, isFinal: Boolean, alternatives: List<String> = emptyList()) {
        eventSink?.success(
            mapOf(
                "transcript" to text,
                "phonemes" to text,
                "alternatives" to alternatives,
                "confidence" to if (text.isBlank()) 0.0 else 1.0,
                "isFinal" to isFinal,
            ),
        )
    }

    private fun buildGrammarJson(activeWords: List<String>, expectedPhrase: String): String? {
        val normalizedWords =
            activeWords
                .map { normalizeArabic(it) }
                .filter { it.isNotBlank() }

        if (normalizedWords.isEmpty()) return null

        val phrases = LinkedHashSet<String>()
        val normalizedExpected = normalizeArabic(expectedPhrase)
        if (normalizedExpected.isNotBlank()) {
            phrases.add(normalizedExpected)
        }

        val maxPrefix = minOf(8, normalizedWords.size)
        for (count in 1..maxPrefix) {
            phrases.add(normalizedWords.take(count).joinToString(" "))
        }

        for (start in normalizedWords.indices) {
            val maxCount = minOf(4, normalizedWords.size - start)
            for (count in 1..maxCount) {
                phrases.add(normalizedWords.drop(start).take(count).joinToString(" "))
            }
        }

        phrases.add("[unk]")

        val array = JSONArray()
        phrases.forEach { array.put(it) }
        return array.toString()
    }

    private fun normalizeArabic(value: String): String {
        return value
            .replace(Regex("[إأآٱ]"), "ا")
            .replace(Regex("[ىئ]"), "ي")
            .replace("ؤ", "و")
            .replace("ة", "ه")
            .replace("ـ", "")
            .replace("ٰ", "ا")
            .replace(Regex("[\\u0610-\\u061A\\u064B-\\u065F\\u06D6-\\u06ED]"), "")
            .replace(Regex("[^\\u0600-\\u06FF ]"), " ")
            .replace(Regex("\\s+"), " ")
            .trim()
    }

    override fun onDestroy() {
        stopVosk()
        model?.close()
        model = null
        super.onDestroy()
    }
}
