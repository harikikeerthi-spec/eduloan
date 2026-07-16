# Flutter video_player / ExoPlayer keep rules
# Without these, R8 strips reflection-based ExoPlayer classes in release builds
# causing VideoPlayerController.asset() to silently fail on real devices.

-keep class io.flutter.plugins.videoplayer.** { *; }
-keep class com.google.android.exoplayer2.** { *; }
-keep class com.google.android.exoplayer2.source.** { *; }
-keep class com.google.android.exoplayer2.extractor.** { *; }
-keep class com.google.android.exoplayer2.text.** { *; }
-keep class com.google.android.exoplayer2.upstream.** { *; }
-keep class com.google.android.exoplayer2.util.** { *; }
-keep class com.google.android.exoplayer2.mediacodec.** { *; }
-keep class com.google.android.exoplayer2.audio.** { *; }
-keep class com.google.android.exoplayer2.video.** { *; }
-dontwarn com.google.android.exoplayer2.**

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
