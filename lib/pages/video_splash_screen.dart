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
  bool _isInCallMode = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  static const MethodChannel _audioChannel =
      MethodChannel('com.vidyaloan/audio_check');

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

  /// Checks if the device is currently in a cellular call or VoIP meet (Google Meet, Zoom, WhatsApp)
  Future<bool> _checkActiveCallOrMeet() async {
    try {
      final bool? inCall = await _audioChannel.invokeMethod<bool>('isInCallOrMeet');
      return inCall ?? false;
    } catch (e) {
      debugPrint('VideoSplashScreen: Call check channel exception: $e');
      return false;
    }
  }

  Future<void> _initializeAndPlay() async {
    // Safety net — max 20 seconds
    Future.delayed(const Duration(seconds: 20), () {
      if (mounted && !_navigated) {
        debugPrint('VideoSplashScreen: Safety timeout reached, navigating.');
        _navigateAway();
      }
    });

    // ── Check if user is in a phone call or Google Meet / Zoom / WhatsApp call ──
    final bool isInCall = await _checkActiveCallOrMeet();
    if (isInCall) {
      debugPrint('VideoSplashScreen: Active phone call or Meet detected. Bypassing video splash.');
      if (mounted && !_navigated) {
        FlutterNativeSplash.remove();
        setState(() {
          _showFallback = true;
          _isInCallMode = true;
        });
        _animController.forward();
        Future.delayed(const Duration(milliseconds: 2500), () {
          if (mounted && !_navigated) _navigateAway();
        });
      }
      return;
    }

    File? tempVideoFile;
    try {
      // ── Step 1: Copy asset bytes to a temp file ──────────────────────────
      final byteData = await rootBundle.load('assets/images/splash_video.mp4');
      final tempDir = await getTemporaryDirectory();
      tempVideoFile = File('${tempDir.path}/splash_video.mp4');
      await tempVideoFile.writeAsBytes(
        byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes),
        flush: true,
      );
      debugPrint('VideoSplashScreen: Video copied to temp file: ${tempVideoFile.path}');

      if (!mounted || _navigated) return;

      // ── Step 2: Initialize player from temp file ─────────────────────────
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
      await _controller?.setVolume(0.0);
      controller.addListener(_videoListener);

      FlutterNativeSplash.remove();

      setState(() {
        _videoReady = true;
      });

      await _controller?.setVolume(0.0);
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
          _videoReady = false;
        });
        _animController.forward();
        Future.delayed(const Duration(milliseconds: 2500), () {
          if (mounted && !_navigated) _navigateAway();
        });
      }
      return;
    }

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

      final String? authToken = prefs.getString('auth_token');
      final String? userId = prefs.getString('userId');
      final bool isLoggedIn =
          authToken != null && authToken.isNotEmpty &&
          userId != null && userId.isNotEmpty;
      final bool onboardingShown = prefs.getBool('onboarding_shown') ?? false;

      if (!mounted) return;

      if (!onboardingShown) {
        // Mandatory Onboarding Page completion first
        Navigator.of(context).pushReplacementNamed('/onboarding');
      } else if (isLoggedIn) {
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      debugPrint('VideoSplashScreen: Navigation error — $e');
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/onboarding');
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
          // Video layer (Only shown when not in call/meet)
          if (_videoReady && ctrl != null && ctrl.value.isInitialized && !_isInCallMode)
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

          // Silent Animated Splash Screen (Shown when in call/meet or on fallback)
          if (_showFallback || _isInCallMode)
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
