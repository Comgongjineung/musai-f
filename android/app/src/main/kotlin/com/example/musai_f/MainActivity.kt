package com.example.musai_f

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.unity3d.player.UnityPlayer

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.musai_f/unity_ar"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "SetJwtToken" -> {
                    val token = (call.arguments as? String).orEmpty()
                    if (token.isBlank()) {
                        result.error("EMPTY_TOKEN", "JWT token is empty", null)
                        return@setMethodCallHandler
                    }
                    try {
                        // 1. Unity 액티비티 실행 + JWT 전달
                        val intent = Intent(this, UnityOverlayActivity::class.java).apply {
                            putExtra("jwt", token)
                        }
                        startActivity(intent)

                        // 2. Unity가 이미 떠 있는 경우를 대비해 즉시 메시지도 시도
                        try {
                            UnityPlayer.UnitySendMessage("ARCamera", "SetJwtToken", token)
                        } catch (_: Exception) {
                        }

                        result.success(null)
                    } catch (e: Exception) {
                        result.error("OPEN_UNITY_ERROR", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}
