package com.idleorbit.idle_orbit

import android.app.Application
import android.content.Context
import android.os.Build
import android.util.Log
import java.io.File

/**
 * Records uncaught JVM crashes (including ones during startup, before any
 * Flutter code runs) to a file. The Dart side shows the report on the next
 * launch so problems on real devices can be diagnosed without adb.
 */
class IdleOrbitApplication : Application() {
    override fun attachBaseContext(base: Context) {
        super.attachBaseContext(base)
        val previous = Thread.getDefaultUncaughtExceptionHandler()
        Thread.setDefaultUncaughtExceptionHandler { thread, error ->
            try {
                File(base.filesDir, CRASH_FILE).writeText(
                    "device: ${Build.MANUFACTURER} ${Build.MODEL} / Android ${Build.VERSION.RELEASE} " +
                        "(API ${Build.VERSION.SDK_INT})\nthread: ${thread.name}\n\n" +
                        Log.getStackTraceString(error)
                )
            } catch (_: Throwable) {
                // Never let crash reporting itself crash.
            }
            previous?.uncaughtException(thread, error)
        }
    }

    companion object {
        const val CRASH_FILE = "last_native_crash.txt"
    }
}
