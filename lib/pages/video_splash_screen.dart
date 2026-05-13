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
  bool _isPlaying = false;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _initializeAndPlay();
  }

  Future<void> _initializeAndPlay() async {
    debugPrint("VideoSplashScreen: Starting video setup...");
    
    try {
      final controller = VideoPlayerController.asset('assets/images/splash_video.mp4');
      _controller = controller;
      
      await controller.initialize();
      debugPrint("VideoSplashScreen: Video initialized.");
      
      if (!mounted) return;

      await controller.setLooping(false);
      await controller.setVolume(0.0); // Muted usually plays more reliably
      
      setState(() {});
      
      await controller.play();
      _isPlaying = true;
      
      // Small delay before removing native splash to ensure video frame is rendered
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) FlutterNativeSplash.remove();
      });
      
      controller.addListener(_videoListener);
    } catch (error) {
      debugPrint("VideoSplashScreen: Error - Could not play splash video: $error");
      if (mounted) {
        FlutterNativeSplash.remove();
        _checkAuthAndNavigate();
      }
    }
  }

  void _videoListener() {
    if (!_navigated &&
        _isPlaying &&
        _controller != null &&
        _controller!.value.isInitialized &&
        (_controller!.value.position >= _controller!.value.duration || 
         (!_controller!.value.isPlaying && _controller!.value.position > Duration.zero))) {
      _navigated = true;
      _isPlaying = false;
      _controller?.removeListener(_videoListener);
      _checkAuthAndNavigate();
    }
  }

  Future<void> _checkAuthAndNavigate() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (!mounted) return;

    if (token != null && token.isNotEmpty) {
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      Navigator.of(context).pushReplacementNamed('/login');
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
    return Scaffold(
      backgroundColor: Colors.black, // Dark background for seamless transition
      body: Center(
        child: (_controller != null && _controller!.value.isInitialized)
            ? SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _controller!.value.size.width,
                    height: _controller!.value.size.height,
                    child: VideoPlayer(_controller!),
                  ),
                ),
              )
            : Container(color: Colors.black),
      ),
    );
  }
}
