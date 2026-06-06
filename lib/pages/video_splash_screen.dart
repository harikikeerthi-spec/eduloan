import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

class VideoSplashScreen extends StatefulWidget {
  const VideoSplashScreen({super.key});

  @override
  State<VideoSplashScreen> createState() => _VideoSplashScreenState();
}

class _VideoSplashScreenState extends State<VideoSplashScreen> {
  VideoPlayerController? _controller;
  bool _navigated = false;

  // The splash video is 4K (2160x3840) which overloads the emulator.
  // Set to false on a real device or after replacing with a lower-res video.
  static const bool skipVideoSplash = false;

  @override
  void initState() {
    super.initState();
    _initializeAndPlay();
  }

  Future<void> _initializeAndPlay() async {
    // Skip the video on emulators — the 4K video blocks the main thread
    if (skipVideoSplash) {
      FlutterNativeSplash.remove();
      _navigate();
      return;
    }

    // Always navigate after 4 seconds max — safety net
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted && !_navigated) {
        debugPrint('VideoSplashScreen: Timeout reached, forcing navigation.');
        FlutterNativeSplash.remove();
        _navigate();
      }
    });

    try {
      final controller = VideoPlayerController.asset('assets/images/splash_video.mp4');
      _controller = controller;

      // Add listener BEFORE initializing so we never miss the end event
      controller.addListener(_videoListener);

      // Timeout the initialize itself to 3 seconds
      await controller.initialize().timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          throw Exception('Video initialization timed out');
        },
      );

      if (!mounted || _navigated) return;

      await controller.setLooping(false);
      await controller.setVolume(0.0);

      setState(() {}); // Show video frame

      FlutterNativeSplash.remove();

      await controller.play();
    } catch (error) {
      debugPrint('VideoSplashScreen: Skipping video splash — $error');
      if (mounted && !_navigated) {
        FlutterNativeSplash.remove();
        _navigate();
      }
    }
  }

  void _videoListener() {
    if (_navigated) return;
    final ctrl = _controller;
    if (ctrl == null || !ctrl.value.isInitialized) return;

    final isFinished = ctrl.value.position >= ctrl.value.duration &&
        ctrl.value.duration > Duration.zero;
    final isStoppedAfterStart = !ctrl.value.isPlaying &&
        ctrl.value.position > Duration.zero &&
        ctrl.value.duration > Duration.zero;

    if (isFinished || isStoppedAfterStart) {
      _navigated = true;
      ctrl.removeListener(_videoListener);
      if (mounted) _navigate();
    }
  }

  Future<void> _navigate() async {
    _navigated = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (!mounted) return;
      if (token != null && token.isNotEmpty) {
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      debugPrint('VideoSplashScreen: Navigation error — $e');
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_videoListener);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = _controller;
    final videoReady = ctrl != null && ctrl.value.isInitialized;

    return Scaffold(
      backgroundColor: Colors.black,
      body: videoReady
          ? SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: ctrl.value.size.width,
                  height: ctrl.value.size.height,
                  child: VideoPlayer(ctrl),
                ),
              ),
            )
          : const SizedBox.shrink(), // transparent until video is ready (theme is now white)
    );
  }
}
