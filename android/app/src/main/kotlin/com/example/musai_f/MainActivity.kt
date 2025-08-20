package com.example.musai_f

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
// import com.unity3d.player.UnityPlayerGameActivity
// import com.unity3d.player.UnityPlayer

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.musai_f/unity_ar"
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "launchUnityAR" -> {
                    try {
                        // Unity 라이브러리가 제대로 생성되지 않아 임시로 주석 처리
                        // val intent = Intent(this, UnityPlayerGameActivity::class.java)
                        // intent.putExtra("unity", "-force-glcore")
                        // startActivity(intent)
                        result.error("UNITY_NOT_AVAILABLE", "Unity library not properly generated", "Please rebuild Unity project first")
                    } catch (e: Exception) {
                        result.error("UNITY_LAUNCH_ERROR", "Failed to launch Unity AR", e.message)
                    }
                }
                "isUnityAvailable" -> {
                    try {
                        // Unity 라이브러리가 로드 가능한지 확인
                        // System.loadLibrary("unity")
                        result.success(false) // 임시로 false 반환
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                "SetJwtToken" -> {
                    try {
                        val token = call.arguments as? String ?: ""
                        // UnityPlayer.UnitySendMessage("ARCamera", "SetJwtToken", token)
                        result.error("UNITY_NOT_AVAILABLE", "Unity library not properly generated", "Please rebuild Unity project first")
                    } catch (e: Exception) {
                        result.error("UNITY_SEND_ERROR", "Failed to send JWT to Unity", e.message)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
