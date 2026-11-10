package com.idleorbit.idle_orbit

import android.app.Activity
import android.content.Intent
import android.os.Bundle

/**
 * Launcher entry point. Routes to a plain (non-Flutter) crash report screen
 * if the previous launch crashed, otherwise straight to the game.
 */
class EntryActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val report = try {
            CrashReports.pendingReport(this)
        } catch (_: Throwable) {
            null
        }
        val next = if (report != null) {
            Intent(this, CrashReportActivity::class.java).putExtra(CrashReportActivity.EXTRA_REPORT, report)
        } else {
            Intent(this, MainActivity::class.java)
        }
        startActivity(next)
        finish()
        overridePendingTransition(0, 0)
    }
}
