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
                // MODE_IN_CALL (2) or MODE_IN_COMMUNICATION (3) indicates active cellular or VoIP call (Google Meet, Zoom, WhatsApp)
                if (mode == AudioManager.MODE_IN_CALL || mode == AudioManager.MODE_IN_COMMUNICATION) {
                    return true
                }
            }

            val telephonyManager = getSystemService(Context.TELEPHONY_SERVICE) as? TelephonyManager
            if (telephonyManager != null) {
                val state = telephonyManager.callState
                // CALL_STATE_OFFHOOK (2) or CALL_STATE_RINGING (1) indicates active call
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
