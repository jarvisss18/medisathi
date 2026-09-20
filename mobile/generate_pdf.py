import os
from reportlab.lib.pagesizes import letter
from reportlab.lib import colors
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, PageBreak, KeepTogether, HRFlowable
)
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.pdfgen import canvas

class NumberedCanvas(canvas.Canvas):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self._saved_page_states = []

    def showPage(self):
        self._saved_page_states.append(dict(self.__dict__))
        self._startPage()

    def save(self):
        num_pages = len(self._saved_page_states)
        for state in self._saved_page_states:
            self.__dict__.update(state)
            self.draw_page_decorations(num_pages)
            super().showPage()
        super().save()

    def draw_page_decorations(self, page_count):
        self.saveState()
        self.setFont("Helvetica-Bold", 8)
        self.setFillColor(colors.HexColor("#044E36")) # Dark green
        
        # Header (pages 2+)
        if self._pageNumber > 1:
            self.drawString(54, 750, "MEDISATHI — Technical Architecture & MVP Video Presentation Guide")
            self.setStrokeColor(colors.HexColor("#D1FAE5"))
            self.setLineWidth(0.75)
            self.line(54, 742, 558, 742)

        # Footer (all pages)
        self.setFont("Helvetica", 8)
        self.setFillColor(colors.HexColor("#64748B"))
        self.drawString(54, 36, "MediSathi MVP Architecture | Offline-First Healthcare Solution")
        self.drawRightString(558, 36, f"Page {self._pageNumber} of {page_count}")
        self.setStrokeColor(colors.HexColor("#E2E8F0"))
        self.setLineWidth(0.5)
        self.line(54, 48, 558, 48)
        
        self.restoreState()

def create_architecture_pdf(output_filename="MediSathi_Architecture_MVP_Guide.pdf"):
    doc = SimpleDocTemplate(
        output_filename,
        pagesize=letter,
        leftMargin=54,
        rightMargin=54,
        topMargin=54,
        bottomMargin=54
    )

    styles = getSampleStyleSheet()
    
    # Custom Palette
    PRIMARY = colors.HexColor("#059669")    # Emerald Green
    PRIMARY_DARK = colors.HexColor("#044E36")# Deep Dark Green
    SECONDARY = colors.HexColor("#1E6FE8")   # Royal Blue
    TEXT_DARK = colors.HexColor("#0F172A")   # Slate Dark
    TEXT_MUTED = colors.HexColor("#475569")  # Slate Muted
    BG_LIGHT = colors.HexColor("#F8FAFC")    # Slate Off-White
    ACCENT_RED = colors.HexColor("#EF4444")  # Alert Red

    # Custom Paragraph Styles
    title_style = ParagraphStyle(
        'DocTitle',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=26,
        leading=32,
        textColor=PRIMARY_DARK,
        spaceAfter=6
    )

    subtitle_style = ParagraphStyle(
        'DocSubtitle',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=13,
        leading=17,
        textColor=PRIMARY,
        spaceAfter=15
    )

    h1_style = ParagraphStyle(
        'H1',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=16,
        leading=20,
        textColor=PRIMARY_DARK,
        spaceBefore=14,
        spaceAfter=8,
        keepWithNext=True
    )

    h2_style = ParagraphStyle(
        'H2',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=12,
        leading=16,
        textColor=SECONDARY,
        spaceBefore=10,
        spaceAfter=6,
        keepWithNext=True
    )

    body_style = ParagraphStyle(
        'Body',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=9.5,
        leading=13.5,
        textColor=TEXT_DARK,
        spaceAfter=6
    )

    bullet_style = ParagraphStyle(
        'Bullet',
        parent=body_style,
        leftIndent=12,
        firstLineIndent=-8,
        spaceAfter=4
    )

    code_style = ParagraphStyle(
        'CodeStyle',
        parent=styles['Normal'],
        fontName='Courier',
        fontSize=8.5,
        leading=11,
        textColor=colors.HexColor("#1E293B"),
        backColor=colors.HexColor("#F1F5F9"),
        borderColor=colors.HexColor("#CBD5E1"),
        borderWidth=0.5,
        borderPadding=6,
        spaceBefore=4,
        spaceAfter=6
    )

    script_heading = ParagraphStyle(
        'ScriptHeading',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=10,
        leading=14,
        textColor=PRIMARY_DARK
    )

    story = []

    # ─── COVER / HEADER SECTION ─────────────────────────────────────────────
    story.append(Spacer(1, 10))
    story.append(Paragraph("MEDISATHI", title_style))
    story.append(Paragraph("Comprehensive Technical Architecture & MVP Video Presentation Guide", subtitle_style))
    story.append(HRFlowable(width="100%", thickness=2, color=PRIMARY, spaceBefore=0, spaceAfter=12))

    meta_data = [
        [Paragraph("<b>Project:</b> MediSathi Mobile MVP", body_style), Paragraph("<b>Target Event:</b> CODEX Hackathon 2026", body_style)],
        [Paragraph("<b>Tech Stack:</b> Flutter, Java/Kotlin, OpenCV/MLKit, Android APIs", body_style), Paragraph("<b>Target OS:</b> Android (Offline-First)", body_style)]
    ]
    t_meta = Table(meta_data, colWidths=[250, 254])
    t_meta.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), colors.HexColor("#F0FDF4")),
        ('PADDING', (0,0), (-1,-1), 8),
        ('BOX', (0,0), (-1,-1), 0.5, colors.HexColor("#A7F3D0")),
        ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
    ]))
    story.append(t_meta)
    story.append(Spacer(1, 14))

    # ─── SECTION 1: EXECUTIVE SUMMARY ───────────────────────────────────────
    story.append(Paragraph("1. Executive Summary & System Philosophy", h1_style))
    story.append(Paragraph(
        "<b>MediSathi</b> is a specialized, offline-first medical adherence and pill-verification ecosystem specifically "
        "designed for elderly patients and rural Indian healthcare settings. It resolves two critical healthcare challenges: "
        "<b>(1) Accidental consumption of lookalike pharmaceutical strips</b>, and <b>(2) Missed medication doses due to standard app notifications being ignored during phone sleep mode.</b>",
        body_style
    ))
    story.append(Paragraph(
        "The system combines a <b>Flutter-based elderly-accessible UI</b> with a <b>Native Java/Android Alarm Engine</b> "
        "operating directly at the Android OS layer. This guarantees 100% reliable full-screen lockscreen alarm triggering even when the app process is terminated or the device is in deep sleep mode.",
        body_style
    ))
    story.append(Spacer(1, 8))

    # ─── SECTION 2: SYSTEM ARCHITECTURE OVERVIEW ─────────────────────────────
    story.append(Paragraph("2. Full Stack Technology Overview", h1_style))

    tech_table_data = [
        [Paragraph("<b>Layer</b>", body_style), Paragraph("<b>Technologies Used</b>", body_style), Paragraph("<b>Core Responsibility</b>", body_style)],
        
        [Paragraph("<b>Frontend Shell</b>", body_style),
         Paragraph("Flutter v3.x, Dart 3,<br/>Material 3 Design", body_style),
         Paragraph("Elderly-friendly responsive UI, 30pt+ typography, HSL green contrast theme, multi-language (EN/HI/MR).", body_style)],
        
        [Paragraph("<b>State & Routing</b>", body_style),
         Paragraph("Flutter Riverpod,<br/>GoRouter", body_style),
         Paragraph("Reactive state management, compile-safe dependency injection, declarative navigation back-stack.", body_style)],
        
        [Paragraph("<b>Native Backend</b>", body_style),
         Paragraph("Java, Kotlin,<br/>Android SDK (API 24-34)", body_style),
         Paragraph("Native <code>AlarmActivity</code>, <code>AlarmReceiver</code>, <code>AlarmManager.setAlarmClock()</code>, <code>PowerManager.FULL_WAKE_LOCK</code>.", body_style)],
        
        [Paragraph("<b>Inter-Process Bridge</b>", body_style),
         Paragraph("Android MethodChannel<br/>(<code>com.bugbusters.../alarm</code>)", body_style),
         Paragraph("Asynchronous bidirectional communication bridge connecting Dart logic with Native Android OS APIs.", body_style)],
        
        [Paragraph("<b>Computer Vision</b>", body_style),
         Paragraph("Google ML Kit OCR,<br/>Camera Stream API", body_style),
         Paragraph("On-device offline OCR text recognition, pill strip active ingredient extraction, blur & contrast validation.", body_style)],
        
        [Paragraph("<b>Data Persistence</b>", body_style),
         Paragraph("SharedPreferences v2,<br/>Offline CSV/JSON Catalog", body_style),
         Paragraph("Persistent storage for saved medicines, daily dose logs timeline, interaction rules database, and caregiver logs.", body_style)],

        [Paragraph("<b>Telephony Integration</b>", body_style),
         Paragraph("Android Intent Scheme<br/>(<code>tel:</code> & <code>sms:</code>)", body_style),
         Paragraph("Direct phone dialing and automated emergency SMS escalation to designated family caregivers.", body_style)]
    ]

    t_tech = Table(tech_table_data, colWidths=[100, 140, 264])
    t_tech.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), PRIMARY_DARK),
        ('TEXTCOLOR', (0,0), (-1,0), colors.white),
        ('PADDING', (0,0), (-1,-1), 6),
        ('GRID', (0,0), (-1,-1), 0.5, colors.HexColor("#CBD5E1")),
        ('VALIGN', (0,0), (-1,-1), 'TOP'),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [colors.white, BG_LIGHT])
    ]))
    story.append(t_tech)
    story.append(Spacer(1, 14))

    # ─── SECTION 3: NATIVE ALARM SYSTEM ──────────────────────────────────────
    story.append(Paragraph("3. Deep-Dive: Native Lock-Screen Alarm System", h1_style))
    story.append(Paragraph(
        "Standard Flutter notifications are frequently suppressed by Android 10+ battery optimizations or ignored when the phone is locked. "
        "MediSathi solves this by bypassing Flutter's UI thread for alarm execution using a multi-layer native Android architecture:",
        body_style
    ))

    story.append(Paragraph("<b>A. Hardware Screen Wake & Lock-Screen Bypass (Java/WindowManager)</b>", h2_style))
    story.append(Paragraph(
        "The native <code>AlarmActivity.java</code> is configured with explicit window flags to take over the phone screen:",
        body_style
    ))
    story.append(Paragraph(
        "• <code>setShowWhenLocked(true)</code> & <code>setTurnScreenOn(true)</code>: Forces device display to turn ON immediately.<br/>"
        "• <code>FLAG_KEEP_SCREEN_ON</code> & <code>FLAG_DISMISS_KEYGUARD</code>: Unlocks keyguard for the alarm dialog.<br/>"
        "• <code>PowerManager.FULL_WAKE_LOCK | ACQUIRE_CAUSES_WAKEUP</code>: Wakes device CPU from deep sleep (Doze mode).",
        bullet_style
    ))

    story.append(Paragraph("<b>B. System Alarm Priority via <code>AlarmManager.setAlarmClock()</code></b>", h2_style))
    story.append(Paragraph(
        "In <code>MainActivity.kt</code>, alarms are scheduled using <code>AlarmManager.setAlarmClock()</code> instead of standard background intents. "
        "In Android OS, <code>setAlarmClock</code> grants high-priority system privileges, displaying a system alarm icon and ensuring execution regardless of battery saver settings.",
        body_style
    ))

    story.append(Paragraph("<b>C. Dual Execution Flow (Locked vs. Active State)</b>", h2_style))
    story.append(Paragraph(
        "• <b>When Phone is Locked / Screen Off:</b> <code>AlarmReceiver.java</code> detects lock state (<code>isKeyguardLocked</code>) and directly launches <code>AlarmActivity</code> full-screen over the lockscreen with looping ringtone.<br/>"
        "• <b>When Phone is Unlocked / Active in another app:</b> Displays a high-priority <b>Heads-Up Banner Notification</b> at the top of the screen to prevent disruptive app switching.",
        bullet_style
    ))
    story.append(Spacer(1, 14))

    story.append(PageBreak())

    # ─── SECTION 4: COMPUTER VISION & VERIFICATION ───────────────────────────
    story.append(Paragraph("4. Computer Vision & Verification Pipeline", h1_style))
    story.append(Paragraph(
        "The pill strip verification engine operates 100% offline to ensure safety in remote areas without internet access. "
        "It consists of four deterministic verification gates:",
        body_style
    ))

    cv_table_data = [
        [Paragraph("<b>Verification Gate</b>", body_style), Paragraph("<b>Mechanism</b>", body_style), Paragraph("<b>Safety Outcome</b>", body_style)],
        [Paragraph("<b>1. Quality Gate</b>", body_style),
         Paragraph("Frame blur detection & lighting contrast analysis.", body_style),
         Paragraph("Rejects blurry or unreadable scans before OCR execution.", body_style)],
        [Paragraph("<b>2. OCR Text Engine</b>", body_style),
         Paragraph("Google ML Kit text recognition extracts brand/canonical names.", body_style),
         Paragraph("Parses pharmaceutical text from physical blister pack.", body_style)],
        [Paragraph("<b>3. Shade & Lookalike Gate</b>", body_style),
         Paragraph("Cross-references strip color signature against database lookalike groups.", body_style),
         Paragraph("Flags lookalike packaging confusion (e.g. Paracetamol vs. Amlodipine).", body_style)],
        [Paragraph("<b>4. Confidence Gate</b>", body_style),
         Paragraph("Multi-factor scoring rules (0.0 to 1.0 confidence).", body_style),
         Paragraph("Enforces high threshold before marking medicine safe to consume.", body_style)]
    ]

    t_cv = Table(cv_table_data, colWidths=[120, 214, 170])
    t_cv.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), PRIMARY),
        ('TEXTCOLOR', (0,0), (-1,0), colors.white),
        ('PADDING', (0,0), (-1,-1), 6),
        ('GRID', (0,0), (-1,-1), 0.5, colors.HexColor("#CBD5E1")),
        ('VALIGN', (0,0), (-1,-1), 'TOP'),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [colors.white, BG_LIGHT])
    ]))
    story.append(t_cv)
    story.append(Spacer(1, 14))

    # ─── SECTION 5: ADHERENCE & CAREGIVER SYSTEM ─────────────────────────────
    story.append(Paragraph("5. Smart Adherence & Caregiver Escalation", h1_style))
    story.append(Paragraph(
        "Adherence tracking is synchronized between local user UI and caregiver notification channels:",
        body_style
    ))
    story.append(Paragraph(
        "• <b>Adherence Logging:</b> Every <b>TAKEN</b> or <b>MISSED</b> action is recorded with ISO-8601 timestamps and persisted in <code>SharedPreferences</code>.<br/>"
        "• <b>Today's Medication Timeline:</b> Displays daily dose history with status badges.<br/>"
        "• <b>Caregiver Escalation:</b> When a dose is marked MISSED or unconfirmed beyond grace window, a <code>MISSED_DOSE</code> event is automatically generated in the Caregiver Center, enabling one-tap phone calls and pre-populated SMS alerts.",
        bullet_style
    ))
    story.append(Spacer(1, 14))

    # ─── SECTION 6: MVP VIDEO PRESENTATION SCRIPT ────────────────────────────
    story.append(Paragraph("6. Step-by-Step Script for MVP Video Demonstration", h1_style))
    story.append(Paragraph(
        "Use this structured scene-by-scene script while recording the application video walkthrough for hackathon evaluation:",
        body_style
    ))

    script_table_data = [
        [Paragraph("<b>Scene / Time</b>", body_style), Paragraph("<b>Visual Action on Screen</b>", body_style), Paragraph("<b>Key Script Narration Point</b>", body_style)],
        
        [Paragraph("<b>Scene 1</b><br/>(0:00 - 0:15)", body_style),
         Paragraph("Show Home Dashboard. Highlight clean green theme, large buttons, and daily reminder cards.", body_style),
         Paragraph("<i>\"Welcome to MediSathi — an offline-first, elderly-friendly medication safety system built for CODEX 2026.\"</i>", body_style)],

        [Paragraph("<b>Scene 2</b><br/>(0:15 - 0:45)", body_style),
         Paragraph("Tap <b>Scan Strip</b>. Aim camera at a pill strip. Perform verification scan. Show verification results screen.", body_style),
         Paragraph("<i>\"MediSathi's on-device AI runs quality, OCR, and lookalike shade checks offline to verify medicine identity and warn against drug interactions.\"</i>", body_style)],

        [Paragraph("<b>Scene 3</b><br/>(0:45 - 1:15)", body_style),
         Paragraph("Go to <b>Reminders</b>. Tap <b>Set Reminder</b>. Add medicine for 1 minute ahead. Save reminder.", body_style),
         Paragraph("<i>\"Setting a reminder configures a high-priority exact alarm natively using Android's AlarmManager.\"</i>", body_style)],

        [Paragraph("<b>Scene 4</b><br/>(1:15 - 1:45)", body_style),
         Paragraph("<b>Lock phone screen completely / turn off display</b>. Wait for alarm time.", body_style),
         Paragraph("<i>\"Watch as the phone screen automatically wakes UP from deep sleep, bypasses the lockscreen, and displays the full-screen Medicine Time alarm!\"</i>", body_style)],

        [Paragraph("<b>Scene 5</b><br/>(1:45 - 2:15)", body_style),
         Paragraph("Tap <b>✔ Mark as Taken</b> on alarm UI. Open app -> show <b>Today's Adherence Timeline</b>.", body_style),
         Paragraph("<i>\"Marking taken logs adherence instantly. If a dose is missed, MediSathi automatically alerts designated family caregivers via SMS.\"</i>", body_style)]
    ]

    t_script = Table(script_table_data, colWidths=[80, 204, 220])
    t_script.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), PRIMARY_DARK),
        ('TEXTCOLOR', (0,0), (-1,0), colors.white),
        ('PADDING', (0,0), (-1,-1), 6),
        ('GRID', (0,0), (-1,-1), 0.5, colors.HexColor("#CBD5E1")),
        ('VALIGN', (0,0), (-1,-1), 'TOP'),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [colors.white, BG_LIGHT])
    ]))
    story.append(t_script)

    # Build Document
    doc.build(story, canvasmaker=NumberedCanvas)
    print(f"Successfully generated PDF: {output_filename}")

if __name__ == "__main__":
    create_architecture_pdf()
