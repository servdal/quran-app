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
import java.util.concurrent.atomic.AtomicBoolean
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import org.json.JSONObject
import org.vosk.Model
import org.vosk.Recognizer

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

        startVoskInternal(path)
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
                recognizer = Recognizer(model, 16000.0f)
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
                    emitResult(error.message ?: "Gagal memuat model Vosk", true)
                }
            }
        }.start()
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
                        emitJson(
                            if (accepted) currentRecognizer.result else currentRecognizer.partialResult,
                            false,
                        )
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

    override fun onDestroy() {
        stopVosk()
        model?.close()
        model = null
        super.onDestroy()
    }
}
