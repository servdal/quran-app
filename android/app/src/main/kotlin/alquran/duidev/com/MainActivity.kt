package alquran.duidev.com

import com.ryanheise.audioservice.AudioServicePlugin
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun provideFlutterEngine(context: android.content.Context): FlutterEngine? {
        return AudioServicePlugin.getFlutterEngine(context)
    }
}
