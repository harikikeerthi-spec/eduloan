# Flutter video_player / Media3 keep rules
# video_player_android 2.9.x uses androidx.media3 (NOT com.google.android.exoplayer2)
# R8 strips these reflection-based classes in release builds causing video to fail silently.

# Media3 (new ExoPlayer - used by video_player_android 2.7+)
-keep class androidx.media3.** { *; }
-keep class androidx.media3.common.** { *; }
-keep class androidx.media3.exoplayer.** { *; }
-keep class androidx.media3.exoplayer.source.** { *; }
-keep class androidx.media3.exoplayer.mediacodec.** { *; }
-keep class androidx.media3.exoplayer.audio.** { *; }
-keep class androidx.media3.exoplayer.video.** { *; }
-keep class androidx.media3.extractor.** { *; }
-keep class androidx.media3.datasource.** { *; }
-keep class androidx.media3.ui.** { *; }
-dontwarn androidx.media3.**

# Old ExoPlayer (kept for backwards compatibility)
-keep class com.google.android.exoplayer2.** { *; }
-dontwarn com.google.android.exoplayer2.**

# video_player Flutter plugin
-keep class io.flutter.plugins.videoplayer.** { *; }
-dontwarn io.flutter.plugins.videoplayer.**

# Keep Flutter plugin registration
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# Firebase
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**
