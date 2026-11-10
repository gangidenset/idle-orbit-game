package com.idleorbit.idle_orbit

import android.app.Activity
import android.content.ClipData
import android.content.ClipboardManager
import android.content.Intent
import android.graphics.Color
import android.graphics.Typeface
import android.os.Bundle
import android.view.ViewGroup.LayoutParams.MATCH_PARENT
import android.view.ViewGroup.LayoutParams.WRAP_CONTENT
import android.widget.Button
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import android.widget.Toast

/** Shows a crash report without Flutter, so it works even if Flutter can't start. */
class CrashReportActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val report = intent.getStringExtra(EXTRA_REPORT).orEmpty()
        val pad = (16 * resources.displayMetrics.density).toInt()

        val title = TextView(this).apply {
            text = "前回の起動でアプリが異常終了しました"
            textSize = 18f
            setTextColor(Color.WHITE)
            setTypeface(typeface, Typeface.BOLD)
        }
        val hint = TextView(this).apply {
            text = "「エラー内容をコピー」を押して、開発者に送ってください。"
            setTextColor(Color.LTGRAY)
            setPadding(0, pad / 2, 0, pad / 2)
        }
        val body = TextView(this).apply {
            text = report
            textSize = 11f
            typeface = Typeface.MONOSPACE
            setTextColor(Color.WHITE)
            setTextIsSelectable(true)
        }
        val scroll = ScrollView(this).apply {
            setBackgroundColor(Color.parseColor("#22000000"))
            addView(body)
        }
        val copy = Button(this).apply {
            text = "エラー内容をコピー"
            setOnClickListener {
                getSystemService(ClipboardManager::class.java)
                    ?.setPrimaryClip(ClipData.newPlainText("IDLE ORBIT crash", report))
                Toast.makeText(this@CrashReportActivity, "コピーしました", Toast.LENGTH_SHORT).show()
            }
        }
        val retry = Button(this).apply {
            text = "もう一度起動する"
            setOnClickListener {
                startActivity(Intent(this@CrashReportActivity, MainActivity::class.java))
                finish()
            }
        }
        setContentView(LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(Color.parseColor("#070E22"))
            setPadding(pad, pad * 2, pad, pad)
            addView(title)
            addView(hint)
            addView(scroll, LinearLayout.LayoutParams(MATCH_PARENT, 0, 1f))
            addView(copy, LinearLayout.LayoutParams(MATCH_PARENT, WRAP_CONTENT))
            addView(retry, LinearLayout.LayoutParams(MATCH_PARENT, WRAP_CONTENT))
        })
    }

    companion object {
        const val EXTRA_REPORT = "report"
    }
}
