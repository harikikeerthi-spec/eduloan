package com.example.vidhyaloan

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioManager
import android.os.Build
import android.telecom.TelecomManager
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
                // 1. Direct audio mode check
                val mode = audioManager.mode
                if (mode == AudioManager.MODE_IN_CALL ||
                    mode == AudioManager.MODE_IN_COMMUNICATION ||
                    mode == AudioManager.MODE_RINGTONE ||
                    (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q && mode == AudioManager.MODE_CALL_SCREENING)) {
                    return true
                }

                // 2. Active audio recording configurations (API 24+)
                // When in ANY call (Cellular, WhatsApp, Google Meet, Zoom, Telegram, Teams),
                // the microphone is actively being recorded by the phone dialer or VoIP client.
                // This public API does NOT require dangerous runtime permissions.
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                    try {
                        val recordingConfigs = audioManager.activeRecordingConfigurations
                        if (!recordingConfigs.isNullOrEmpty()) {
                            return true
                        }
                    } catch (_: Exception) {}
                }

                // 3. Active audio playback configurations (API 26+)
                // Detect voice communication, call signalling, or ringtones active across the system
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    try {
                        val playbacks = audioManager.activePlaybackConfigurations
                        for (playback in playbacks) {
                            val usage = playback.audioAttributes.usage
                            if (usage == AudioAttributes.USAGE_VOICE_COMMUNICATION ||
                                usage == AudioAttributes.USAGE_VOICE_COMMUNICATION_SIGNALLING ||
                                usage == AudioAttributes.USAGE_NOTIFICATION_RINGTONE ||
                                usage == 17 /* AudioAttributes.USAGE_CALL_ASSISTANT (API 30+) */) {
                                return true
                            }
                        }
                    } catch (_: Exception) {}
                }

                // 4. Communication device check (API 31+)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    try {
                        val commDevice = audioManager.communicationDevice
                        if (commDevice != null) {
                            return true
                        }
                    } catch (_: Exception) {}
                }

                // 5. Hardware routing check during active communication
                try {
                    if (audioManager.isSpeakerphoneOn || audioManager.isBluetoothScoOn) {
                        if (mode != AudioManager.MODE_NORMAL) {
                            return true
                        }
                    }
                } catch (_: Exception) {}
            }

            // 6. TelecomManager check (API 26+)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                try {
                    val telecomManager = getSystemService(Context.TELECOM_SERVICE) as? TelecomManager
                    if (telecomManager != null) {
                        try {
                            if (telecomManager.isInCall) {
                                return true
                            }
                        } catch (_: Exception) {}
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            try {
                                if (telecomManager.isInManagedCall) {
                                    return true
                                }
                            } catch (_: Exception) {}
                        }
                    }
                } catch (_: Exception) {}
            }

            // 7. TelephonyManager callState check (safely wrapped in its own try-catch)
            try {
                val telephonyManager = getSystemService(Context.TELEPHONY_SERVICE) as? TelephonyManager
                if (telephonyManager != null) {
                    val state = telephonyManager.callState
                    if (state == TelephonyManager.CALL_STATE_OFFHOOK || state == TelephonyManager.CALL_STATE_RINGING) {
                        return true
                    }
                }
            } catch (_: Exception) {}

        } catch (e: Exception) {
            e.printStackTrace()
        }
        return false
    }
}
