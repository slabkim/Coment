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
        // Check if this is a notification click
        val action = intent.action
        android.util.Log.d("MainActivity", "Intent action: $action")
        
        // Only handle FLUTTER_NOTIFICATION_CLICK or notification extras
        if (action != "FLUTTER_NOTIFICATION_CLICK" && 
            intent.extras?.containsKey("type") != true) {
            return
        }
        
        val notificationData = mutableMapOf<String, String>()
        
        // Extract all FCM data payload
        intent.extras?.keySet()?.forEach { key ->
            android.util.Log.d("MainActivity", "Intent extra key: $key")
            // Skip system keys
            if (!key.startsWith("google.") && 
                !key.startsWith("gcm.") && 
                !key.startsWith("from") && 
                key != "collapse_key" &&
                key != "androidx.contentpager.content.wakelockid") {
                val value = intent.extras?.get(key)
                if (value != null) {
                    notificationData[key] = value.toString()
                    android.util.Log.d("MainActivity", "Added data: $key = $value")
                }
            }
        }
        
        android.util.Log.d("MainActivity", "Notification data size: ${notificationData.size}")
        
        if (notificationData.isNotEmpty()) {
            if (methodChannel != null) {
                android.util.Log.d("MainActivity", "Invoking method channel with data")
                methodChannel?.invokeMethod("onNotificationTap", notificationData)
            } else {
                android.util.Log.d("MainActivity", "Method channel not ready, storing pending data")
                pendingNotificationData = notificationData
            }
        }
    }
}
