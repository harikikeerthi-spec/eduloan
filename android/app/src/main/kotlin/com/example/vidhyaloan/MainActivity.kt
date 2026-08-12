package com.example.vidhyaloan

import android.content.Context
import android.media.AudioManager
import android.telephony.TelephonyManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.vidyaloan/audio_check"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "isInCallOrMeet") {
                val inCall = checkCallStatus()
                result.success(inCall)
            } else {
                result.notImplemented()
            }
        }
    }

    private fun checkCallStatus(): Boolean {
        try {
            val audioManager = getSystemService(Context.AUDIO_SERVICE) as? AudioManager
            if (audioManager != null) {
                val mode = audioManager.mode
                // Any mode other than MODE_NORMAL (0) indicates an active phone call, ringtone, or VoIP meet (Google Meet, Zoom, WhatsApp, Teams)
                if (mode != AudioManager.MODE_NORMAL) {
                    return true
                }
                if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.S) {
                    val commDevice = audioManager.communicationDevice
                    if (commDevice != null) {
                        return true
                    }
                }
            }

            val telephonyManager = getSystemService(Context.TELEPHONY_SERVICE) as? TelephonyManager
            if (telephonyManager != null) {
                val state = telephonyManager.callState
                if (state == TelephonyManager.CALL_STATE_OFFHOOK || state == TelephonyManager.CALL_STATE_RINGING) {
                    return true
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
        return false
    }
}
