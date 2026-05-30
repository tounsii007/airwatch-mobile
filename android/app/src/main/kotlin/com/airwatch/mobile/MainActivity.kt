package com.airwatch.mobile

import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.airwatch.mobile/screen_security"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // FLAG_SECURE set app-wide BEFORE MethodChannel registration so the
        // very first frame is already screenshot-blocked. The Dart-side
        // ScreenSecurity.enable() call was async over a MethodChannel and
        // left a 1–2 frame race window where the recent-apps thumbnail or
        // an instant screenshot could leak sensitive data. The MethodChannel
        // `enable`/`disable` is retained for explicit opt-out on non-
        // sensitive screens where the operator may want screenshots.
        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "enable" -> {
                    window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    result.success(null)
                }
                "disable" -> {
                    window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }
}
