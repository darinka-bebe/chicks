package com.example.chicks

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant

/**
 * Flutter embedding v2 entry point.
 *
 * Registers plugins via [GeneratedPluginRegistrant] so native channels
 * (permission_handler, image_picker, etc.) are available at runtime.
 */
class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Ensures plugins are registered after full rebuild (avoids MissingPluginException
        // when the engine is created without going through the default path).
        GeneratedPluginRegistrant.registerWith(flutterEngine)
    }
}
