# ──────────────────────────────────────────────────────────────────────────────
# AI Journal — ProGuard / R8 rules for release builds
# ──────────────────────────────────────────────────────────────────────────────

# record_android (llfbandit/record) — audio recording plugin.
# R8 would otherwise strip classes accessed by the Flutter plugin registry.
-keep class com.llfbandit.record.** { *; }

# Flutter plugin registry — keep all FlutterPlugin implementations.
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.view.** { *; }

# OkHttp / http package (used by WhisperTranscriptionService)
-dontwarn okhttp3.**
-dontwarn okio.**

# Flutter deferred components — Play Core classes not used in this app
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# Google services / Firebase
-keep class com.google.android.gms.** { *; }
-keep class com.google.firebase.** { *; }
