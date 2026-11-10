package com.idleorbit.idle_orbit

import android.app.Application
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Process
import android.util.Log
import java.io.File
import kotlin.system.exitProcess

/**
 * Records uncaught JVM crashes and shows them immediately in a separate
 * ":crash" process. This also covers crashes during app startup (content
 * providers / SDK initialisation), which happen before any activity exists:
 * content providers are not created in the ":crash" process, so the report
 * screen can open even when the main process can't start at all.
 */
class IdleOrbitApplication : Application() {
    override fun attachBaseContext(base: Context) {
        super.attachBaseContext(base)
        if (currentProcessName().endsWith(":crash")) return

        val previous = Thread.getDefaultUncaughtExceptionHandler()
        Thread.setDefaultUncaughtExceptionHandler { thread, error ->
            val report = "device: ${Build.MANUFACTURER} ${Build.MODEL} / Android ${Build.VERSION.RELEASE} " +
                "(API ${Build.VERSION.SDK_INT})\nabis: ${Build.SUPPORTED_ABIS.joinToString()}\n" +
                "thread: ${thread.name}\n\n== JVM crash ==\n" + Log.getStackTraceString(error).take(12000)
            try {
                File(base.filesDir, CRASH_FILE).writeText(report)
            } catch (_: Throwable) {
            }
            val shown = try {
                base.startActivity(
                    Intent(base, CrashReportActivity::class.java)
                        .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK)
                        .putExtra(CrashReportActivity.EXTRA_REPORT, report)
                )
                // Shown in the report screen; don't show it again next launch.
                File(base.filesDir, CRASH_FILE).delete()
                true
            } catch (_: Throwable) {
                false
            }
            if (shown) {
                Process.killProcess(Process.myPid())
                exitProcess(10)
            } else {
                previous?.uncaughtException(thread, error)
            }
        }
    }

    private fun currentProcessName(): String {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) return getProcessName()
        return try {
            File("/proc/self/cmdline").readText().trim('\u0000', ' ', '\n')
        } catch (_: Throwable) {
            ""
        }
    }

    companion object {
        const val CRASH_FILE = "last_native_crash.txt"
    }
}
