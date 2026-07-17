import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:google_fonts/google_fonts.dart';

class VideoSplashScreen extends StatefulWidget {
  const VideoSplashScreen({super.key});

  @override
  State<VideoSplashScreen> createState() => _VideoSplashScreenState();
}

class _VideoSplashScreenState extends State<VideoSplashScreen>
    with SingleTickerProviderStateMixin {
  VideoPlayerController? _controller;
  bool _navigated = false;
  bool _videoReady = false;
  bool _showFallback = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _scaleAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );
    _initializeAndPlay();
  }

  Future<void> _initializeAndPlay() async {
    // Safety net — always navigate after 20 seconds max
    Future.delayed(const Duration(seconds: 20), () {
      if (mounted && !_navigated) {
        debugPrint('VideoSplashScreen: Safety timeout reached, navigating.');
        _navigateAway();
      }
    });

    File? tempVideoFile;
    try {
      // ─── Step 1: Copy asset bytes to a temp file ──────────────────────────
      // VideoPlayerController.asset() silently fails on Android release builds.
      // The file-based approach is 100% reliable on all real devices.
      final byteData = await rootBundle.load('assets/images/splash_video.mp4');
      final tempDir = await getTemporaryDirectory();
      tempVideoFile = File('${tempDir.path}/splash_video.mp4');
      await tempVideoFile.writeAsBytes(
        byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes),
        flush: true,
      );
      debugPrint('VideoSplashScreen: Video copied to temp file: ${tempVideoFile.path}');

      if (!mounted || _navigated) return;

      // ─── Step 2: Initialize player from temp file ─────────────────────────
      final controller = VideoPlayerController.file(tempVideoFile);
      _controller = controller;

      await controller.initialize().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Video initialization timed out after 15s');
        },
      );

      if (!mounted || _navigated) return;

      await controller.setLooping(false);
      await controller.setVolume(0.0);
      controller.addListener(_videoListener);

      FlutterNativeSplash.remove();

      setState(() {
        _videoReady = true;
      });

      await controller.play();
      debugPrint('VideoSplashScreen: Video playing successfully.');
    } catch (error) {
      debugPrint('VideoSplashScreen: Video failed — $error. Showing fallback.');
      try { await tempVideoFile?.delete(); } catch (_) {}
      if (mounted && !_navigated) {
        FlutterNativeSplash.remove();
        setState(() => _showFallback = true);
        _animController.forward();
        Future.delayed(const Duration(milliseconds: 2500), () {
          if (mounted && !_navigated) _navigateAway();
        });
      }
    }
  }

  void _videoListener() {
    if (_navigated) return;
    final ctrl = _controller;
    if (ctrl == null || !ctrl.value.isInitialized) return;

    if (ctrl.value.hasError) {
      debugPrint('VideoSplashScreen: Player error — ${ctrl.value.errorDescription}');
      if (mounted && !_navigated) {
        ctrl.removeListener(_videoListener);
        FlutterNativeSplash.remove();
        setState(() {
          _showFallback = true;
          _videoReady = false; // hide video layer so fallback renders cleanly
        });
        _animController.forward();
        Future.delayed(const Duration(milliseconds: 2500), () {
          if (mounted && !_navigated) _navigateAway();
        });
      }
      return;
    }

    // Navigate when video has finished
    final isFinished = ctrl.value.duration > Duration.zero &&
        ctrl.value.position >= ctrl.value.duration;

    if (isFinished) {
      debugPrint('VideoSplashScreen: Video finished, navigating.');
      ctrl.removeListener(_videoListener);
      _navigateAway();
    }
  }

  Future<void> _navigateAway() async {
    if (_navigated) return;
    _navigated = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      // Clear session tokens on every app launch to force re-login
      await prefs.remove('auth_token');
      await prefs.remove('refresh_token');
      await prefs.remove('latest_ai_recommendations');
      await prefs.remove('user_profileImage');
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/login');
    } catch (e) {
      debugPrint('VideoSplashScreen: Navigation error — $e');
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _controller?.removeListener(_videoListener);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = _controller;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Video layer
          if (_videoReady && ctrl != null && ctrl.value.isInitialized)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: ctrl.value.size.width,
                  height: ctrl.value.size.height,
                  child: VideoPlayer(ctrl),
                ),
              ),
            ),

          // Fallback animated logo splash
          if (_showFallback)
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1A0050),
                    Color(0xFF311B92),
                    Color(0xFF4A148C),
                  ],
                ),
              ),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: ScaleTransition(
                  scale: _scaleAnim,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.25),
                              width: 1.5,
                            ),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Image.asset(
                            'assets/images/logo_transparent.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Vidya Loans',
                          style: GoogleFonts.outfit(
                            fontSize: 34,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your Dream. Our Support.',
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            color: Colors.white70,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 48),
                        SizedBox(
                          width: 36,
                          height: 36,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
