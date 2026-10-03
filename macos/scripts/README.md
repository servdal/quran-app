# macOS build compatibility

Build from the repository root with `flutter build macos --release`.
The minimum deployment target is macOS 15.5 for the app, tests, and CocoaPods
targets, matching the bundled ONNX Runtime requirement. The app requires
macOS 15.5 or later.

The Xcode scheme's Flutter preparation action and both Flutter build phases
prepend `scripts/bin` to `PATH`. The local `lipo` wrapper works around Xcode 27
rejecting Flutter's multi-architecture `-verify_arch` invocation: it verifies
each requested architecture separately and fails if any is missing. All other
operations are forwarded to `/usr/bin/lipo` unchanged. Universal builds retain
both Apple Silicon and Intel architectures, without modifying the Flutter SDK.

Remove the wrapper and the three PATH additions once Flutter and Xcode support
the original multi-architecture verification together.
