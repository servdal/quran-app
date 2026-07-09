package alquran.duidev.com

import android.Manifest
import android.annotation.SuppressLint
import android.content.pm.PackageManager
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import android.os.Looper
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.ArrayDeque
import java.util.concurrent.atomic.AtomicBoolean
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import org.json.JSONArray
import org.json.JSONObject
import org.vosk.Model
import org.vosk.Recognizer
import com.ryanheise.audioservice.AudioServicePlugin

class MainActivity : FlutterActivity() {
    private val controlChannelName = "quran_app/offline_recitation/control"
    private val eventChannelName = "quran_app/offline_recitation/events"

    private var eventSink: EventChannel.EventSink? = null
    private var model: Model? = null
    private var recognizer: Recognizer? = null
    private var audioRecord: AudioRecord? = null
    private var recognitionThread: Thread? = null
    private var modelPath: String? = null
    private var modelId: String? = null
    private var activeWords: List<String> = emptyList()
    private var expectedPhrase: String = ""
    private var isLoading = false
    private var pendingStartAfterPermission = false
    private var lastAudioDebugAtMs = 0L
    private val isListening = AtomicBoolean(false)
    private val maxMicGain = 3.0f

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
                        activeWords =
                            (call.argument<List<Any>>("activeWords") ?: emptyList())
                                .mapNotNull { it as? String }
                                .filter { it.isNotBlank() }
                        expectedPhrase = call.argument<String>("expectedPhrase").orEmpty()
                        val path = modelPath
                        if (modelId != "vosk_arabic") {
                            result.error(
                                "UNSUPPORTED_MODEL",
                                "Android recognizer saat ini memakai Vosk Arabic. Pilih model Vosk Arabic.",
                                null,
                            )
                            return@setMethodCallHandler
                        }
                        val resolvedPath = resolveVoskModelPath(path)
                        if (resolvedPath == null) {
                            result.error("MODEL_NOT_FOUND", "Model Vosk Arabic belum ditemukan.", path)
                            return@setMethodCallHandler
                        }
                        if (modelPath != resolvedPath) {
                            stopVosk()
                            model?.close()
                            model = null
                            modelPath = resolvedPath
                        } else {
                            stopVosk()
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
        val resolvedPath = resolveVoskModelPath(path)
        if (resolvedPath == null) {
            result.error("MODEL_NOT_FOUND", "Model Vosk Arabic belum ditemukan.", path)
            return
        }
        if (isListening.get() || isLoading) {
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

        modelPath = resolvedPath
        startVoskInternal(resolvedPath)
        result.success(null)
    }

    private fun startVoskInternal(path: String) {
        if (isListening.get() || isLoading) return

        isLoading = true
        Thread {
            try {
                if (model == null) {
                    model = Model(path)
                }
                val grammar = buildVoskGrammar()
                recognizer =
                    if (grammar == null) {
                        Recognizer(model, 16000.0f)
                    } else {
                        Recognizer(model, 16000.0f, grammar)
                    }
                recognizer?.setWords(true)
                recognizer?.setPartialWords(true)
                recognizer?.setMaxAlternatives(3)
                runOnUiThread {
                    isLoading = false
                    startAudioLoop()
                }
            } catch (error: Exception) {
                runOnUiThread {
                    isLoading = false
                    emitEngineError(error.message ?: "Gagal memuat model Vosk")
                }
            }
        }.start()
    }
    override fun provideFlutterEngine(context: android.content.Context): FlutterEngine? {
        return AudioServicePlugin.getFlutterEngine(context)
    }

    @SuppressLint("MissingPermission")
    private fun startAudioLoop() {
        val currentRecognizer = recognizer ?: return
        if (!isListening.compareAndSet(false, true)) return

        recognitionThread =
            Thread {
                val sampleRate = 16000
                var recorder: AudioRecord? = null

                try {
                    val minBuffer =
                        AudioRecord.getMinBufferSize(
                            sampleRate,
                            AudioFormat.CHANNEL_IN_MONO,
                            AudioFormat.ENCODING_PCM_16BIT,
                        )
                    if (minBuffer <= 0) {
                        emitResult("Mikrofon belum siap", true)
                        return@Thread
                    }

                    val recorderBufferSize = maxOf(minBuffer, sampleRate * 2)
                    recorder =
                        AudioRecord(
                            MediaRecorder.AudioSource.VOICE_RECOGNITION,
                            sampleRate,
                            AudioFormat.CHANNEL_IN_MONO,
                            AudioFormat.ENCODING_PCM_16BIT,
                            recorderBufferSize,
                        )
                    audioRecord = recorder

                    if (recorder.state != AudioRecord.STATE_INITIALIZED) {
                        emitResult("Mikrofon gagal dibuka", true)
                        return@Thread
                    }

                    recorder.startRecording()
                    val buffer = ShortArray(sampleRate / 10)

                    while (isListening.get()) {
                        val read = recorder.read(buffer, 0, buffer.size)
                        if (read <= 0) continue

                        applyAdaptiveMicGain(buffer, read)
                        emitAudioDebug(buffer, read)
                        val accepted = currentRecognizer.acceptWaveForm(buffer, read)
                        val hypothesis =
                            if (accepted) currentRecognizer.result else currentRecognizer.partialResult
                        if (accepted || hasRecognizedText(hypothesis)) {
                            emitJson(hypothesis, accepted)
                        }
                    }

                    emitJson(currentRecognizer.finalResult, true)
                } catch (error: Exception) {
                    emitResult(error.message ?: "Pengenalan suara gagal", true)
                } finally {
                    try {
                        recorder?.stop()
                    } catch (_: Exception) {
                    }
                    recorder?.release()
                    audioRecord = null
                    isListening.set(false)
                }
            }
        recognitionThread?.start()
    }

    private fun emitAudioDebug(buffer: ShortArray, length: Int) {
        val now = System.currentTimeMillis()
        if (now - lastAudioDebugAtMs < 250) return
        lastAudioDebugAtMs = now

        var peak = 0
        var sumSquares = 0.0
        for (index in 0 until length) {
            val amplitude = kotlin.math.abs(buffer[index].toInt())
            if (amplitude > peak) peak = amplitude
            sumSquares += amplitude.toDouble() * amplitude.toDouble()
        }

        val rms =
            kotlin.math.sqrt(sumSquares / length.toDouble()) /
                Short.MAX_VALUE.toDouble()
        val peakLevel = peak.toDouble() / Short.MAX_VALUE.toDouble()
        val normalizedRms = rms.coerceIn(0.0, 1.0)
        val normalizedPeak = peakLevel.coerceIn(0.0, 1.0)

        Log.d(
            "OfflineRecitation",
            "mic samples=$length rms=${"%.4f".format(normalizedRms)} peak=${"%.4f".format(normalizedPeak)}",
        )
        emitResult(
            text = "",
            isFinal = false,
            confidence = normalizedRms,
            extras =
                mapOf(
                    "debugType" to "audio",
                    "micLevel" to normalizedRms,
                    "peakLevel" to normalizedPeak,
                    "audioSamples" to length,
                    "debugMessage" to "Mic aktif, audio masuk ke Vosk",
                ),
        )
    }

    private fun applyAdaptiveMicGain(buffer: ShortArray, length: Int) {
        var peak = 0
        for (index in 0 until length) {
            val amplitude = kotlin.math.abs(buffer[index].toInt())
            if (amplitude > peak) peak = amplitude
        }

        if (peak == 0) return

        val peakLevel = peak.toFloat() / Short.MAX_VALUE.toFloat()
        val targetPeak = 0.65f
        val gain = (targetPeak / peakLevel).coerceIn(1.0f, maxMicGain)

        for (index in 0 until length) {
            buffer[index] =
                (buffer[index] * gain)
                    .toInt()
                    .coerceIn(Short.MIN_VALUE.toInt(), Short.MAX_VALUE.toInt())
                    .toShort()
        }
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
        isListening.set(false)
        try {
            audioRecord?.stop()
        } catch (_: Exception) {
        }
        if (Thread.currentThread() != recognitionThread) {
            try {
                recognitionThread?.join(700)
            } catch (_: InterruptedException) {
                Thread.currentThread().interrupt()
            }
        }
        recognitionThread = null
        recognizer?.close()
        recognizer = null
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

    private fun hasRecognizedText(hypothesis: String?): Boolean {
        val parsed =
            try {
                JSONObject(hypothesis ?: "{}")
            } catch (_: Exception) {
                null
            }
        return parsed?.optString("text")?.isNotBlank() == true ||
            parsed?.optString("partial")?.isNotBlank() == true
    }

    private fun emitResult(
        text: String,
        isFinal: Boolean,
        alternatives: List<String> = emptyList(),
        confidence: Double = if (text.isBlank()) 0.0 else 1.0,
        extras: Map<String, Any> = emptyMap(),
    ) {
        if (Looper.myLooper() != Looper.getMainLooper()) {
            runOnUiThread { emitResult(text, isFinal, alternatives, confidence, extras) }
            return
        }

        eventSink?.success(
            mapOf(
                "transcript" to text,
                "phonemes" to text,
                "alternatives" to alternatives,
                "confidence" to confidence,
                "isFinal" to isFinal,
            ) + extras,
        )
    }

    private fun emitEngineError(message: String) {
        emitResult(
            text = "",
            isFinal = true,
            extras =
                mapOf(
                    "debugType" to "error",
                    "debugMessage" to message,
                ),
        )
    }

    private fun resolveVoskModelPath(path: String?): String? {
        if (path.isNullOrBlank()) return null

        val root = File(path)
        if (!root.exists()) return null
        if (isVoskModelRoot(root)) return root.absolutePath

        val pending = ArrayDeque<File>()
        pending.add(root)
        var scanned = 0

        while (pending.isNotEmpty() && scanned < 80) {
            val current = pending.removeFirst()
            scanned++
            current.listFiles()?.forEach { child ->
                if (!child.isDirectory) return@forEach
                if (isVoskModelRoot(child)) return child.absolutePath
                pending.add(child)
            }
        }

        return null
    }

    private fun isVoskModelRoot(dir: File): Boolean {
        return File(dir, "am").isDirectory &&
            File(dir, "conf").isDirectory &&
            File(dir, "graph").isDirectory
    }

    private fun buildVoskGrammar(): String? {
        val phrases = linkedSetOf<String>()
        val cleanWords =
            activeWords
                .map { normalizeArabicForGrammar(it) }
                .filter { it.isNotEmpty() }

        if (expectedPhrase.isNotBlank()) {
            normalizeArabicForGrammar(expectedPhrase).takeIf { it.isNotEmpty() }?.let {
                phrases.add(it)
            }
        }

        for (index in cleanWords.indices) {
            val maxEnd = minOf(cleanWords.size, index + 6)
            for (end in index + 1..maxEnd) {
                phrases.add(cleanWords.subList(index, end).joinToString(" "))
            }
        }

        if (phrases.isEmpty()) return null
        val grammar = JSONArray()
        phrases.take(250).forEach { grammar.put(it) }
        return grammar.toString()
    }

    private fun normalizeArabicForGrammar(value: String): String {
        return value
            .replace(Regex("[\\u0610-\\u061A\\u064B-\\u065F\\u06D6-\\u06ED]"), "")
            .replace("ـ", "")
            .replace("ٰ", "ا")
            .replace(Regex("[إأآٱ]"), "ا")
            .replace("ى", "ي")
            .replace("ؤ", "و")
            .replace("ئ", "ي")
            .replace(Regex("[^\\u0600-\\u06FF\\s]"), " ")
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
