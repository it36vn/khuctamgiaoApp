package com.thuongag.khuctamgiao

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.provider.Settings
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.core.app.NotificationManagerCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val methodChannelName = "khuctamgiao/notifications"
    private val eventChannelName = "khuctamgiao/notifications/events"
    private val universalLinkMethodChannelName = "khuctamgiao/universal_links"
    private val universalLinkEventChannelName = "khuctamgiao/universal_links/events"
    private var initialNotification: Map<String, Any?>? = null
    private var initialUniversalLink: String? = null
    private var eventSink: EventChannel.EventSink? = null
    private var universalLinkEventSink: EventChannel.EventSink? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        initialUniversalLink = universalLinkFromIntent(intent)
        if (initialUniversalLink == null) {
            initialNotification = payloadFromIntent(intent)
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, methodChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getInitialNotification" -> result.success(initialNotification)
                    "clearInitialNotification" -> {
                        initialNotification = null
                        result.success(null)
                    }
                    "requestPermission" -> {
                        requestPostNotificationPermission()
                        result.success(hasPostNotificationPermission())
                    }
                    "areNotificationsEnabled" -> result.success(areNotificationsEnabled())
                    "openNotificationSettings" -> {
                        openNotificationSettings()
                        result.success(null)
                    }
                    "getDeviceToken" -> result.success(null)
                    else -> result.notImplemented()
                }
            }

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

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, universalLinkMethodChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getInitialLink" -> result.success(initialUniversalLink)
                    "clearInitialLink" -> {
                        initialUniversalLink = null
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, universalLinkEventChannelName)
            .setStreamHandler(
                object : EventChannel.StreamHandler {
                    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                        universalLinkEventSink = events
                    }

                    override fun onCancel(arguments: Any?) {
                        universalLinkEventSink = null
                    }
                },
            )
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val universalLink = universalLinkFromIntent(intent)
        if (universalLink != null) {
            if (universalLinkEventSink == null) {
                initialUniversalLink = universalLink
            } else {
                universalLinkEventSink?.success(universalLink)
            }
            return
        }

        val payload = payloadFromIntent(intent) ?: return
        if (eventSink == null) {
            initialNotification = payload
        } else {
            eventSink?.success(payload)
        }
    }

    private fun payloadFromIntent(intent: Intent?): Map<String, Any?>? {
        if (intent == null) return null
        val extras = intent.extras
        val payload = mutableMapOf<String, Any?>()
        if (extras != null) {
            for (key in extras.keySet()) {
                val value = extras.get(key)
                if (value is String || value is Number || value is Boolean) {
                    payload[key] = value
                }
            }
        }
        if (payload["url"] == null && intent.dataString != null) {
            payload["url"] = intent.dataString
        }
        val dataUrl = payload["data_url"] ?: payload["data.url"]
        if (payload["url"] == null && dataUrl != null) {
            payload["url"] = dataUrl
        }
        return if (payload.isEmpty()) null else payload
    }

    private fun universalLinkFromIntent(intent: Intent?): String? {
        if (intent?.action != Intent.ACTION_VIEW) return null
        return intent.dataString
    }

    private fun hasPostNotificationPermission(): Boolean {
        return Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
            ContextCompat.checkSelfPermission(
                this,
                Manifest.permission.POST_NOTIFICATIONS,
            ) == PackageManager.PERMISSION_GRANTED
    }

    private fun areNotificationsEnabled(): Boolean {
        return hasPostNotificationPermission() &&
            NotificationManagerCompat.from(this).areNotificationsEnabled()
    }

    private fun openNotificationSettings() {
        val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).apply {
                putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
            }
        } else {
            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = android.net.Uri.parse("package:$packageName")
            }
        }
        startActivity(intent)
    }

    private fun requestPostNotificationPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU && !hasPostNotificationPermission()) {
            ActivityCompat.requestPermissions(
                this,
                arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                1208,
            )
        }
    }
}
