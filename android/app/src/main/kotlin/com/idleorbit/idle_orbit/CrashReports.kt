package com.idleorbit.idle_orbit

import android.app.ActivityManager
import android.app.ApplicationExitInfo
import android.content.Context
import android.os.Build
import android.system.Os
import android.system.OsConstants
import java.io.File
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Collects why the previous launch died, without any Flutter code running:
 * the JVM crash file written by IdleOrbitApplication, and on Android 11+ the
 * OS's own exit record (covers native crashes and ANRs as well).
 */
object CrashReports {
    private const val PREFS = "crash_reports"
    private const val KEY_LAST_EXIT_TS = "last_exit_ts"

    fun pendingReport(context: Context): String? {
        val parts = mutableListOf<String>()

        val javaCrash = File(context.filesDir, IdleOrbitApplication.CRASH_FILE)
        if (javaCrash.exists()) {
            parts += "== JVM crash ==\n" + javaCrash.readText().take(12000)
            javaCrash.delete()
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            exitInfoReport(context)?.let { parts += it }
        }
        if (parts.isEmpty()) return null
        return deviceInfo(context) + "\n\n" + parts.joinToString("\n\n")
    }

    private fun exitInfoReport(context: Context): String? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) return null
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val lastSeen = prefs.getLong(KEY_LAST_EXIT_TS, 0L)
        val am = context.getSystemService(ActivityManager::class.java) ?: return null
        val exits = try {
            am.getHistoricalProcessExitReasons(context.packageName, 0, 5)
        } catch (_: Throwable) {
            return null
        }
        val newest = exits.maxOfOrNull { it.timestamp } ?: return null
        prefs.edit().putLong(KEY_LAST_EXIT_TS, newest).apply()

        val crashes = exits.filter {
            it.timestamp > lastSeen && it.reason in setOf(
                ApplicationExitInfo.REASON_CRASH,
                ApplicationExitInfo.REASON_CRASH_NATIVE,
                ApplicationExitInfo.REASON_ANR,
                ApplicationExitInfo.REASON_INITIALIZATION_FAILURE,
                ApplicationExitInfo.REASON_SIGNALED,
            )
        }
        if (crashes.isEmpty()) return null
        val e = crashes.maxByOrNull { it.timestamp }!!
        val fmt = SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.US)
        val sb = StringBuilder("== Exit info ==\n")
            .append("time: ").append(fmt.format(Date(e.timestamp))).append('\n')
            .append("reason: ").append(reasonName(e.reason)).append('\n')
            .append("status: ").append(e.status).append('\n')
            .append("description: ").append(e.description).append('\n')
        trace(e)?.let { sb.append("\n== Trace ==\n").append(it) }
        return sb.toString()
    }

    /** ANR traces are text; native tombstones are protobuf, so keep readable strings. */
    private fun trace(e: ApplicationExitInfo): String? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) return null
        val bytes = try {
            e.traceInputStream?.use { it.readBytes() }
        } catch (_: Throwable) {
            null
        } ?: return null
        if (e.reason == ApplicationExitInfo.REASON_ANR) return String(bytes).take(12000)
        val out = StringBuilder()
        val cur = StringBuilder()
        for (b in bytes) {
            val c = b.toInt() and 0xff
            if (c in 0x20..0x7e) {
                cur.append(c.toChar())
            } else {
                if (cur.length >= 6) out.append(cur).append('\n')
                cur.setLength(0)
            }
            if (out.length > 12000) break
        }
        return out.toString()
    }

    private fun reasonName(r: Int) = when (r) {
        ApplicationExitInfo.REASON_CRASH -> "CRASH (Java/Kotlin)"
        ApplicationExitInfo.REASON_CRASH_NATIVE -> "CRASH_NATIVE"
        ApplicationExitInfo.REASON_ANR -> "ANR"
        ApplicationExitInfo.REASON_INITIALIZATION_FAILURE -> "INITIALIZATION_FAILURE"
        ApplicationExitInfo.REASON_SIGNALED -> "SIGNALED"
        else -> r.toString()
    }

    private fun deviceInfo(context: Context): String {
        val pkg = context.packageManager.getPackageInfo(context.packageName, 0)
        val pageSize = try { Os.sysconf(OsConstants._SC_PAGESIZE) } catch (_: Throwable) { -1L }
        return "app: ${pkg.versionName}\n" +
            "device: ${Build.MANUFACTURER} ${Build.MODEL}\n" +
            "android: ${Build.VERSION.RELEASE} (API ${Build.VERSION.SDK_INT})\n" +
            "abis: ${Build.SUPPORTED_ABIS.joinToString()}\n" +
            "page size: $pageSize"
    }
}
