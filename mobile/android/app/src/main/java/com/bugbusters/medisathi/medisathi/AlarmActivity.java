package com.bugbusters.medisathi.medisathi;

import android.app.Activity;
import android.app.AlarmManager;
import android.app.KeyguardManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.graphics.Color;
import android.graphics.Typeface;
import android.media.AudioAttributes;
import android.media.AudioManager;
import android.media.RingtoneManager;
import android.media.Ringtone;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.os.Vibrator;
import android.os.VibratorManager;
import android.os.VibrationEffect;
import android.view.Gravity;
import android.view.View;
import android.view.Window;
import android.view.WindowManager;
import android.widget.Button;
import android.widget.FrameLayout;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.TextView;

/**
 * Full-screen alarm Activity — shown over the lock screen / when app is killed.
 *
 * The UI mirrors the green "Medicine Time!" dialog designed by the team.
 * It works completely without Flutter; no Dart engine is needed.
 */
public class AlarmActivity extends Activity {

    private Ringtone ringtone;
    private Vibrator vibrator;
    private Handler autoStopHandler = new Handler(Looper.getMainLooper());
    private static final int AUTO_DISMISS_MS = 90_000; // 90 seconds

    // ─── Lifecycle ─────────────────────────────────────────────────────────────

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        // ── Wake the screen & show above lock screen ──────────────────────────
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true);
            setTurnScreenOn(true);
            KeyguardManager km = (KeyguardManager) getSystemService(KEYGUARD_SERVICE);
            if (km != null) km.requestDismissKeyguard(this, null);
        }

        getWindow().addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED
                | WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
                | WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
                | WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD
                | WindowManager.LayoutParams.FLAG_FULLSCREEN);

        // ── Parse intent extras ───────────────────────────────────────────────
        String medicineName = getIntent().getStringExtra("medicine_name");
        String doseText     = getIntent().getStringExtra("dose_text");
        String timeStr      = getIntent().getStringExtra("time_str");
        int    notifId      = getIntent().getIntExtra("notif_id", 0);

        if (medicineName == null) medicineName = "Your Medicine";
        if (doseText     == null) doseText     = "1 Tablet";
        if (timeStr      == null) timeStr      = "";

        // ── Play alarm ringtone on alarm stream ───────────────────────────────
        Uri alarmUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM);
        if (alarmUri == null)
            alarmUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION);

        ringtone = RingtoneManager.getRingtone(getApplicationContext(), alarmUri);
        if (ringtone != null) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) ringtone.setLooping(true);
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                ringtone.setAudioAttributes(new AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                        .build());
            }
            ringtone.play();
        }

        // ── Vibrate ───────────────────────────────────────────────────────────
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            VibratorManager vm = (VibratorManager) getSystemService(VIBRATOR_MANAGER_SERVICE);
            if (vm != null) vibrator = vm.getDefaultVibrator();
        } else {
            vibrator = (Vibrator) getSystemService(VIBRATOR_SERVICE);
        }
        if (vibrator != null) {
            long[] pattern = {0, 600, 400, 600, 400};
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                vibrator.vibrate(VibrationEffect.createWaveform(pattern, 0));
            } else {
                vibrator.vibrate(pattern, 0);
            }
        }

        // ── Build UI ──────────────────────────────────────────────────────────
        setContentView(buildAlarmUI(medicineName, doseText, timeStr, notifId));

        // ── Auto-dismiss after AUTO_DISMISS_MS ────────────────────────────────
        autoStopHandler.postDelayed(this::dismiss, AUTO_DISMISS_MS);
    }

    @Override
    protected void onDestroy() {
        stopAlarm();
        autoStopHandler.removeCallbacksAndMessages(null);
        super.onDestroy();
    }

    @Override
    public void onBackPressed() {
        // Prevent accidental back-dismiss
    }

    // ─── Build the full alarm UI programmatically ───────────────────────────

    private View buildAlarmUI(String medName, String doseText, String timeStr, int notifId) {
        int green      = Color.parseColor("#059669");
        int darkGreen  = Color.parseColor("#044E36");
        int white      = Color.WHITE;
        int lightGreen = Color.parseColor("#D1FAE5");
        int gold       = Color.parseColor("#FBBF24");
        int textDark   = Color.parseColor("#0F172A");
        int textGray   = Color.parseColor("#64748B");
        int blueDark   = Color.parseColor("#1E6FE8");

        int dp4  = dp(4);
        int dp8  = dp(8);
        int dp12 = dp(12);
        int dp16 = dp(16);
        int dp20 = dp(20);
        int dp24 = dp(24);

        // Root scroll view
        ScrollView scroll = new ScrollView(this);
        scroll.setBackgroundColor(darkGreen);

        // Gradient-style outer container (simulate with solid color)
        LinearLayout root = new LinearLayout(this);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setGravity(Gravity.CENTER_HORIZONTAL);
        root.setBackgroundColor(darkGreen);
        root.setPadding(dp24, dp(40), dp24, dp24);

        // ── Bell icon circle ──────────────────────────────────────────────────
        FrameLayout bellWrap = new FrameLayout(this);
        bellWrap.setLayoutParams(new LinearLayout.LayoutParams(dp(110), dp(110)));
        bellWrap.setBackgroundColor(Color.TRANSPARENT);

        // Outer circle (gold border)
        View outerCircle = new View(this);
        outerCircle.setLayoutParams(new FrameLayout.LayoutParams(dp(110), dp(110)));
        outerCircle.setBackgroundColor(Color.TRANSPARENT);

        TextView bellIcon = new TextView(this);
        bellIcon.setText("🔔");
        bellIcon.setTextSize(52);
        bellIcon.setGravity(Gravity.CENTER);
        FrameLayout.LayoutParams bellParams = new FrameLayout.LayoutParams(dp(110), dp(110));
        bellIcon.setLayoutParams(bellParams);
        bellWrap.addView(outerCircle);
        bellWrap.addView(bellIcon);

        LinearLayout.LayoutParams bellWrapParams = new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT);
        bellWrapParams.gravity = Gravity.CENTER_HORIZONTAL;
        bellWrapParams.bottomMargin = dp20;
        bellWrap.setLayoutParams(bellWrapParams);
        root.addView(bellWrap);

        // ── "Medicine Time!" title ────────────────────────────────────────────
        TextView titleTv = new TextView(this);
        titleTv.setText("Medicine Time!");
        titleTv.setTextSize(30);
        titleTv.setTypeface(null, Typeface.BOLD);
        titleTv.setTextColor(white);
        titleTv.setGravity(Gravity.CENTER);
        LinearLayout.LayoutParams titleParams = new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT);
        titleParams.bottomMargin = dp8;
        titleTv.setLayoutParams(titleParams);
        root.addView(titleTv);

        // ── Subtitle ──────────────────────────────────────────────────────────
        TextView subtitleTv = new TextView(this);
        subtitleTv.setText("It's time to take your medicine.");
        subtitleTv.setTextSize(16);
        subtitleTv.setTextColor(lightGreen);
        subtitleTv.setGravity(Gravity.CENTER);
        LinearLayout.LayoutParams subtitleParams = new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT);
        subtitleParams.bottomMargin = dp24;
        subtitleTv.setLayoutParams(subtitleParams);
        root.addView(subtitleTv);

        // ── White medicine info card ──────────────────────────────────────────
        LinearLayout card = new LinearLayout(this);
        card.setOrientation(LinearLayout.VERTICAL);
        card.setBackgroundColor(white);
        card.setPadding(dp20, dp20, dp20, dp20);

        // Apply rounded corners via outline
        card.setClipToOutline(true);
        android.graphics.drawable.GradientDrawable cardBg = new android.graphics.drawable.GradientDrawable();
        cardBg.setCornerRadius(dp(24));
        cardBg.setColor(white);
        card.setBackground(cardBg);

        LinearLayout.LayoutParams cardParams = new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT);
        cardParams.bottomMargin = dp20;
        card.setLayoutParams(cardParams);

        // Medicine name
        TextView medNameTv = new TextView(this);
        medNameTv.setText(medName);
        medNameTv.setTextSize(22);
        medNameTv.setTypeface(null, Typeface.BOLD);
        medNameTv.setTextColor(textDark);
        LinearLayout.LayoutParams mnParams = new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT);
        mnParams.bottomMargin = dp12;
        medNameTv.setLayoutParams(mnParams);
        card.addView(medNameTv);

        // Dose row
        addInfoRow(card, "💊  " + doseText, textGray, 16);

        // Timing row
        addInfoRow(card, "🍽️  After breakfast", green, 16);

        // Time row
        if (!timeStr.isEmpty()) {
            addInfoRow(card, "🕐  " + timeStr, blueDark, 15);
        }

        // ── Buttons inside card ───────────────────────────────────────────────
        card.addView(spacer(dp16));

        // MARK AS TAKEN
        Button takenBtn = new Button(this);
        takenBtn.setText("✔  Mark as Taken");
        takenBtn.setTextSize(18);
        takenBtn.setTypeface(null, Typeface.BOLD);
        takenBtn.setTextColor(white);

        android.graphics.drawable.GradientDrawable takenBg = new android.graphics.drawable.GradientDrawable();
        takenBg.setCornerRadius(dp(16));
        takenBg.setColor(green);
        takenBtn.setBackground(takenBg);

        LinearLayout.LayoutParams takenParams = new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT, dp(56));
        takenParams.bottomMargin = dp(14);
        takenBtn.setLayoutParams(takenParams);
        takenBtn.setOnClickListener(v -> markTaken(medName));
        card.addView(takenBtn);

        // Row: Snooze buttons
        LinearLayout snoozeRow = new LinearLayout(this);
        snoozeRow.setOrientation(LinearLayout.HORIZONTAL);
        snoozeRow.setWeightSum(2f);

        // Remind in 15min
        Button remind15 = new Button(this);
        remind15.setText("⏰  15 min");
        remind15.setTextSize(14);
        remind15.setTypeface(null, Typeface.BOLD);
        remind15.setTextColor(green);
        android.graphics.drawable.GradientDrawable r15bg = new android.graphics.drawable.GradientDrawable();
        r15bg.setCornerRadius(dp(14));
        r15bg.setStroke(dp(2), green);
        r15bg.setColor(white);
        remind15.setBackground(r15bg);
        LinearLayout.LayoutParams r15Params = new LinearLayout.LayoutParams(0, dp(52), 1f);
        r15Params.rightMargin = dp(6);
        remind15.setLayoutParams(r15Params);
        remind15.setOnClickListener(v -> snooze(medName, doseText, timeStr, notifId, 15));
        snoozeRow.addView(remind15);

        // Snooze 5 min
        Button snooze5 = new Button(this);
        snooze5.setText("⏱️  Snooze 5");
        snooze5.setTextSize(14);
        snooze5.setTypeface(null, Typeface.BOLD);
        snooze5.setTextColor(blueDark);
        android.graphics.drawable.GradientDrawable s5bg = new android.graphics.drawable.GradientDrawable();
        s5bg.setCornerRadius(dp(14));
        s5bg.setStroke(dp(2), blueDark);
        s5bg.setColor(white);
        snooze5.setBackground(s5bg);
        LinearLayout.LayoutParams s5Params = new LinearLayout.LayoutParams(0, dp(52), 1f);
        s5Params.leftMargin = dp(6);
        snooze5.setLayoutParams(s5Params);
        snooze5.setOnClickListener(v -> snooze(medName, doseText, timeStr, notifId, 5));
        snoozeRow.addView(snooze5);

        card.addView(snoozeRow);
        root.addView(card);

        // ── Tagline ───────────────────────────────────────────────────────────
        TextView tagline = new TextView(this);
        tagline.setText("🌿  \"Your health matters\"");
        tagline.setTextSize(15);
        tagline.setTextColor(lightGreen);
        tagline.setGravity(Gravity.CENTER);
        tagline.setTypeface(null, Typeface.ITALIC);
        root.addView(tagline);

        scroll.addView(root);
        return scroll;
    }

    // ─── Actions ─────────────────────────────────────────────────────────────

    private void markTaken(String medName) {
        stopAlarm();
        dismiss();
    }

    private void snooze(String medName, String doseText, String timeStr, int notifId, int minutes) {
        stopAlarm();

        // Re-schedule via AlarmManager after `minutes` minutes
        long triggerAt = System.currentTimeMillis() + (long) minutes * 60 * 1000L;

        Intent intent = new Intent(this, AlarmReceiver.class);
        intent.putExtra("medicine_name", medName);
        intent.putExtra("dose_text",     doseText);
        intent.putExtra("time_str",      timeStr);
        intent.putExtra("notif_id",      notifId);

        int flags = PendingIntent.FLAG_UPDATE_CURRENT;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) flags |= PendingIntent.FLAG_IMMUTABLE;

        PendingIntent pi = PendingIntent.getBroadcast(this, notifId + minutes, intent, flags);
        AlarmManager am = (AlarmManager) getSystemService(ALARM_SERVICE);
        if (am != null) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                am.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAt, pi);
            } else {
                am.setExact(AlarmManager.RTC_WAKEUP, triggerAt, pi);
            }
        }

        dismiss();
    }

    private void stopAlarm() {
        if (ringtone != null && ringtone.isPlaying()) ringtone.stop();
        if (vibrator != null) vibrator.cancel();
    }

    private void dismiss() {
        if (!isFinishing()) finish();
    }

    // ─── Helpers ─────────────────────────────────────────────────────────────

    private int dp(int value) {
        float density = getResources().getDisplayMetrics().density;
        return Math.round(value * density);
    }

    private void addInfoRow(LinearLayout parent, String text, int color, int sizeSp) {
        TextView tv = new TextView(this);
        tv.setText(text);
        tv.setTextSize(sizeSp);
        tv.setTextColor(color);
        LinearLayout.LayoutParams p = new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT);
        p.bottomMargin = dp(6);
        tv.setLayoutParams(p);
        parent.addView(tv);
    }

    private View spacer(int heightPx) {
        View v = new View(this);
        v.setLayoutParams(new LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, heightPx));
        return v;
    }
}
