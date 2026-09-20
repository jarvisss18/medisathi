package com.bugbusters.medisathi.medisathi

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.bugbusters.medisathi/alarm"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "scheduleAlarm" -> {
                        val triggerMs    = call.argument<Long>("triggerMs") ?: return@setMethodCallHandler result.error("MISSING", "triggerMs required", null)
                        val medicineName = call.argument<String>("medicineName") ?: "Your Medicine"
                        val doseText     = call.argument<String>("doseText")     ?: "1 Tablet"
                        val timeStr      = call.argument<String>("timeStr")      ?: ""
                        val notifId      = call.argument<Int>("notifId")         ?: 0

                        scheduleAlarm(triggerMs, medicineName, doseText, timeStr, notifId)
                        result.success(true)
                    }
                    "cancelAlarm" -> {
                        val notifId = call.argument<Int>("notifId") ?: 0
                        cancelAlarm(notifId)
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun scheduleAlarm(
        triggerMs: Long,
        medicineName: String,
        doseText: String,
        timeStr: String,
        notifId: Int,
    ) {
        val am = getSystemService(Context.ALARM_SERVICE) as AlarmManager

        // Intent to launch AlarmReceiver
        val receiverIntent = Intent(this, AlarmReceiver::class.java).apply {
            putExtra("medicine_name", medicineName)
            putExtra("dose_text",     doseText)
            putExtra("time_str",      timeStr)
            putExtra("notif_id",      notifId)
        }

        // Intent to launch AlarmActivity directly when user taps the system alarm icon
        val activityIntent = Intent(this, AlarmActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
            putExtra("medicine_name", medicineName)
            putExtra("dose_text",     doseText)
            putExtra("time_str",      timeStr)
            putExtra("notif_id",      notifId)
        }

        var flags = PendingIntent.FLAG_UPDATE_CURRENT
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            flags = flags or PendingIntent.FLAG_IMMUTABLE
        }

        val operationPI = PendingIntent.getBroadcast(this, notifId, receiverIntent, flags)
        val showPI      = PendingIntent.getActivity(this, notifId + 10000, activityIntent, flags)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            val clockInfo = AlarmManager.AlarmClockInfo(triggerMs, showPI)
            am.setAlarmClock(clockInfo, operationPI)
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            am.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerMs, operationPI)
        } else {
            am.setExact(AlarmManager.RTC_WAKEUP, triggerMs, operationPI)
        }
    }

    private fun cancelAlarm(notifId: Int) {
        val intent = Intent(this, AlarmReceiver::class.java)
        var flags = PendingIntent.FLAG_UPDATE_CURRENT
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) flags = flags or PendingIntent.FLAG_IMMUTABLE
        val pi = PendingIntent.getBroadcast(this, notifId, intent, flags)
        val am = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        am.cancel(pi)
    }
}
