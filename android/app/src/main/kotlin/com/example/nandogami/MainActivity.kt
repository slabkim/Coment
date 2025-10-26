package com.example.nandogami

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL = "com.example.nandogami/notification"
    }

    private var methodChannel: MethodChannel? = null
    private var pendingNotificationData: Map<String, String>? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        intent?.let { handleNotificationIntent(it) }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleNotificationIntent(intent)
        setIntent(intent)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        
        pendingNotificationData?.let { data ->
            methodChannel?.invokeMethod("onNotificationTap", data)
            pendingNotificationData = null
        }
    }

    private fun handleNotificationIntent(intent: Intent) {
        val notificationData = mutableMapOf<String, String>()
        
        intent.extras?.keySet()?.forEach { key ->
            if (!key.startsWith("google.") && !key.startsWith("gcm.") && 
                !key.startsWith("from") && key != "collapse_key") {
                val value = intent.extras?.get(key)
                if (value != null) {
                    notificationData[key] = value.toString()
                }
            }
        }
        
        if (notificationData.isNotEmpty()) {
            if (methodChannel != null) {
                methodChannel?.invokeMethod("onNotificationTap", notificationData)
            } else {
                pendingNotificationData = notificationData
            }
        }
    }
}
