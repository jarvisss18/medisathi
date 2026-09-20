package com.bugbusters.medisathi.medisathi;

import android.app.KeyguardManager;
import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.media.AudioAttributes;
import android.media.RingtoneManager;
import android.net.Uri;
import android.os.Build;
import android.os.PowerManager;
import androidx.core.app.NotificationCompat;

/**
 * Handles alarm trigger logic:
 * 1. If phone screen is OFF or LOCKED: Directly launches full-screen AlarmActivity
 *    and wakes screen immediately (like actual system alarm app).
 * 2. If phone is UNLOCKED & user actively using another app: Shows heads-up banner notification.
 */
public class AlarmReceiver extends BroadcastReceiver {

    private static final String CHANNEL_ID = "medisathi_fullscreen_alarm";

    @Override
    public void onReceive(Context context, Intent intent) {
        String medicineName = intent.getStringExtra("medicine_name");
        String doseText     = intent.getStringExtra("dose_text");
        String timeStr      = intent.getStringExtra("time_str");
        int    notifId      = intent.getIntExtra("notif_id", 0);

        if (medicineName == null) medicineName = "Your Medicine";
        if (doseText     == null) doseText     = "1 Tablet";
        if (timeStr      == null) timeStr      = "";

        PowerManager pm = (PowerManager) context.getSystemService(Context.POWER_SERVICE);
        KeyguardManager km = (KeyguardManager) context.getSystemService(Context.KEYGUARD_SERVICE);

        boolean isInteractive = pm != null && pm.isInteractive();
        boolean isLocked      = km != null && km.isKeyguardLocked();

        // Prepare Intent for AlarmActivity
        Intent alarmIntent = new Intent(context, AlarmActivity.class);
        alarmIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK
                | Intent.FLAG_ACTIVITY_CLEAR_TOP
                | Intent.FLAG_ACTIVITY_SINGLE_TOP);
        alarmIntent.putExtra("medicine_name", medicineName);
        alarmIntent.putExtra("dose_text",     doseText);
        alarmIntent.putExtra("time_str",      timeStr);
        alarmIntent.putExtra("notif_id",      notifId);

        int flags = PendingIntent.FLAG_UPDATE_CURRENT;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            flags |= PendingIntent.FLAG_IMMUTABLE;
        }

        PendingIntent fullScreenPendingIntent = PendingIntent.getActivity(
                context,
                notifId + 20000,
                alarmIntent,
                flags);

        // Wake screen hardware
        if (pm != null) {
            @SuppressWarnings("deprecation")
            PowerManager.WakeLock wakeLock = pm.newWakeLock(
                    PowerManager.FULL_WAKE_LOCK
                    | PowerManager.ACQUIRE_CAUSES_WAKEUP
                    | PowerManager.ON_AFTER_RELEASE,
                    "medisathi:AlarmWakeLock");
            wakeLock.acquire(15_000L);
        }

        // Always post notification with fullScreenIntent so system lock screen handles it natively
        NotificationManager nm = (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);
        if (nm != null) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                NotificationChannel channel = new NotificationChannel(
                        CHANNEL_ID,
                        "Full Screen Alarm Notifications",
                        NotificationManager.IMPORTANCE_HIGH);
                channel.setDescription("Full-screen alarms for medication reminders");
                channel.setLockscreenVisibility(Notification.VISIBILITY_PUBLIC);
                Uri alarmSound = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM);
                AudioAttributes aa = new AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                        .build();
                channel.setSound(alarmSound, aa);
                channel.enableVibration(true);
                nm.createNotificationChannel(channel);
            }

            NotificationCompat.Builder builder = new NotificationCompat.Builder(context, CHANNEL_ID)
                    .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
                    .setContentTitle("⏰ Medicine Time: " + medicineName)
                    .setContentText(doseText + " - Tap to open alarm screen")
                    .setPriority(NotificationCompat.PRIORITY_MAX)
                    .setCategory(NotificationCompat.CATEGORY_ALARM)
                    .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
                    .setAutoCancel(true)
                    .setFullScreenIntent(fullScreenPendingIntent, true)
                    .setContentIntent(fullScreenPendingIntent);

            nm.notify(notifId + 50000, builder.build());
        }

        // IF PHONE IS LOCKED OR SCREEN OFF: Launch activity directly RIGHT NOW
        if (!isInteractive || isLocked) {
            try {
                context.startActivity(alarmIntent);
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    }
}
