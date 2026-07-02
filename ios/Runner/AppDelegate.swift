import AVFoundation
import Flutter
import Speech
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var recitationBridge: DarwinRecitationBridge?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    if let controller = window?.rootViewController as? FlutterViewController {
      recitationBridge = DarwinRecitationBridge(messenger: controller.binaryMessenger)
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

final class DarwinRecitationBridge: NSObject, FlutterStreamHandler {
  private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "ar-SA"))
  private let audioEngine = AVAudioEngine()
  private var request: SFSpeechAudioBufferRecognitionRequest?
  private var task: SFSpeechRecognitionTask?
  private var eventSink: FlutterEventSink?
  private var activeWords: [String] = []
  private var expectedPhrase = ""

  init(messenger: FlutterBinaryMessenger) {
    super.init()

    FlutterEventChannel(
      name: "quran_app/offline_recitation/events",
      binaryMessenger: messenger
    ).setStreamHandler(self)

    FlutterMethodChannel(
      name: "quran_app/offline_recitation/control",
      binaryMessenger: messenger
    ).setMethodCallHandler { [weak self] call, result in
      guard let self else { return }
      switch call.method {
      case "isAvailable":
        result(self.recognizer != nil)
      case "configure":
        let args = call.arguments as? [String: Any]
        self.activeWords = args?["activeWords"] as? [String] ?? []
        self.expectedPhrase = args?["expectedPhrase"] as? String ?? ""
        result(nil)
      case "start":
        self.start(result: result)
      case "stop":
        self.stop()
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    eventSink = events
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    return nil
  }

  private func start(result: @escaping FlutterResult) {
    guard let recognizer else {
      result(FlutterError(code: "UNAVAILABLE", message: "Speech recognizer Arab tidak tersedia.", details: nil))
      return
    }

    SFSpeechRecognizer.requestAuthorization { [weak self] speechStatus in
      guard let self else { return }
      AVAudioSession.sharedInstance().requestRecordPermission { micGranted in
        DispatchQueue.main.async {
          guard speechStatus == .authorized, micGranted else {
            result(FlutterError(code: "PERMISSION_DENIED", message: "Izin mikrofon/pengenalan suara ditolak.", details: nil))
            return
          }

          do {
            try self.startRecognition(recognizer: recognizer)
            result(nil)
          } catch {
            result(FlutterError(code: "START_FAILED", message: error.localizedDescription, details: nil))
          }
        }
      }
    }
  }

  private func startRecognition(recognizer: SFSpeechRecognizer) throws {
    stop()

    let audioSession = AVAudioSession.sharedInstance()
    try audioSession.setCategory(.record, mode: .measurement, options: [.duckOthers])
    try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

    let request = SFSpeechAudioBufferRecognitionRequest()
    request.shouldReportPartialResults = true
    request.contextualStrings = contextualStrings()
    if recognizer.supportsOnDeviceRecognition {
      request.requiresOnDeviceRecognition = true
    }

    self.request = request

    let inputNode = audioEngine.inputNode
    let format = inputNode.outputFormat(forBus: 0)
    inputNode.removeTap(onBus: 0)
    inputNode.installTap(onBus: 0, bufferSize: 2048, format: format) { [weak request] buffer, _ in
      request?.append(buffer)
    }

    audioEngine.prepare()
    try audioEngine.start()

    task = recognizer.recognitionTask(with: request) { [weak self] result, error in
      guard let self else { return }
      if let result {
        self.emit(text: result.bestTranscription.formattedString, isFinal: result.isFinal)
        if result.isFinal {
          self.stop()
        }
      } else if let error {
        self.emit(text: error.localizedDescription, isFinal: true)
        self.stop()
      }
    }
  }

  private func stop() {
    if audioEngine.isRunning {
      audioEngine.stop()
      audioEngine.inputNode.removeTap(onBus: 0)
    }
    request?.endAudio()
    request = nil
    task?.cancel()
    task = nil
  }

  private func contextualStrings() -> [String] {
    var phrases = activeWords.map(normalizeArabic).filter { !$0.isEmpty }
    let expected = normalizeArabic(expectedPhrase)
    if !expected.isEmpty {
      phrases.insert(expected, at: 0)
    }
    return Array(NSOrderedSet(array: phrases)) as? [String] ?? phrases
  }

  private func normalizeArabic(_ value: String) -> String {
    var text = value
    text = text.replacingOccurrences(of: "[إأآٱ]", with: "ا", options: .regularExpression)
    text = text.replacingOccurrences(of: "[ىئ]", with: "ي", options: .regularExpression)
    text = text.replacingOccurrences(of: "ؤ", with: "و")
    text = text.replacingOccurrences(of: "ة", with: "ه")
    text = text.replacingOccurrences(of: "ـ", with: "")
    text = text.replacingOccurrences(of: "ٰ", with: "ا")
    text = text.replacingOccurrences(
      of: "[\\u{0610}-\\u{061A}\\u{064B}-\\u{065F}\\u{06D6}-\\u{06ED}]",
      with: "",
      options: .regularExpression
    )
    text = text.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
    return text.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  private func emit(text: String, isFinal: Bool) {
    eventSink?([
      "transcript": text,
      "phonemes": text,
      "alternatives": [],
      "confidence": text.isEmpty ? 0.0 : 1.0,
      "isFinal": isFinal,
    ])
  }
}
