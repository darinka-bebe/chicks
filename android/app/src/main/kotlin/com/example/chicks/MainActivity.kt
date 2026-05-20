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
        // Register plugins BEFORE super so firebase_core channel exists
        // before Dart calls Firebase.initializeApp (via AppStartupGate).
        GeneratedPluginRegistrant.registerWith(flutterEngine)
        super.configureFlutterEngine(flutterEngine)
    }
}
