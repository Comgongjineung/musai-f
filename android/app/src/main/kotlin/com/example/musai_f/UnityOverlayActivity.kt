package com.example.musai_f

import android.graphics.Color
import android.graphics.Typeface
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.FrameLayout
import android.widget.TextView
import com.unity3d.player.UnityPlayer
import com.unity3d.player.UnityPlayerActivity

class UnityOverlayActivity : UnityPlayerActivity() {

    private val uiHandler = Handler(Looper.getMainLooper())
    private var appBar: View? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        addOverlayAppBar(title = "musai")
    }

    override fun onResume() {
        super.onResume()
        val token = intent?.getStringExtra("jwt").orEmpty()
        if (token.isNotBlank()) {
            uiHandler.postDelayed({
                try {
                    UnityPlayer.UnitySendMessage("ARCamera", "SetJwtToken", token)
                } catch (_: Exception) {
                }
            }, 300)
        }
    }

    private fun addOverlayAppBar(title: String) {
        val root = findViewById<ViewGroup>(android.R.id.content)
        (appBar?.parent as? ViewGroup)?.removeView(appBar)

        val barHeightPx = dp(60f)
        val topOffset = statusBarHeight() + dp(10f) // 상단에서 얼마나 떨어져있는지 조절

        val bar = FrameLayout(this).apply {
            layoutParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                barHeightPx
            ).apply {
                gravity = Gravity.TOP
                topMargin = topOffset
            }
            setBackgroundColor(Color.TRANSPARENT)
        }

        val backBtn = Button(this).apply {
            text = "\u276E"
            setTextColor(Color.rgb(254, 253, 252))
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 28f)
            typeface = Typeface.create(typeface, Typeface.BOLD)
            val lp = FrameLayout.LayoutParams(dp(44f), dp(32f))
            lp.leftMargin = dp(24f)
            lp.gravity = Gravity.CENTER_VERTICAL or Gravity.START
            layoutParams = lp
            setBackgroundColor(Color.TRANSPARENT)
            setOnClickListener { onUnityBack() }
        }
        bar.addView(backBtn)

        val titleView = TextView(this).apply {
            text = title
            gravity = Gravity.CENTER
            setTextColor(Color.rgb(254, 253, 252))
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 32f)
            typeface = Typeface.create(typeface, Typeface.BOLD)
            layoutParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
            )
        }
        bar.addView(titleView)

        root.addView(bar)
        root.bringChildToFront(bar)
        appBar = bar
    }

    private fun onUnityBack() {
        (appBar?.parent as? ViewGroup)?.removeView(appBar)
        appBar = null
        finish()
        uiHandler.postDelayed({
            try {
                // Unity 종료 후 정리 필요 시 확장 가능
            } catch (_: Exception) {
            }
        }, 100)
    }

    private fun dp(value: Float): Int =
        TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, value, resources.displayMetrics).toInt()

    private fun statusBarHeight(): Int {
        val resId = resources.getIdentifier("status_bar_height", "dimen", "android")
        return if (resId > 0) resources.getDimensionPixelSize(resId) else 0
    }
}