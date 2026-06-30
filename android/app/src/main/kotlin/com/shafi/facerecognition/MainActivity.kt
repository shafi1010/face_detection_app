package com.shafi.facerecognition

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import androidx.biometric.BiometricManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.facewatch/native"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        createNotificationChannels()

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isBiometricAvailable" -> {
                    val biometricManager = BiometricManager.from(this)
                    val status = biometricManager.canAuthenticate(BiometricManager.Authenticators.BIOMETRIC_STRONG)
                    result.success(status == BiometricManager.BIOMETRIC_SUCCESS)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager

            val criticalChannel = NotificationChannel(
                "critical_alerts",
                "Critical Alerts",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Blacklist matches and critical security alerts"
                enableVibration(true)
                setSound(null, null)
                enableLights(true)
                lightColor = 0xFFFF5252.toInt()
            }

            val infoChannel = NotificationChannel(
                "info_alerts",
                "Information Alerts",
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = "Unknown faces and general notifications"
            }

            notificationManager.createNotificationChannel(criticalChannel)
            notificationManager.createNotificationChannel(infoChannel)
        }
    }
}
