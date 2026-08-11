import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ImageCropDialog extends StatefulWidget {
  final Uint8List imageBytes;

  const ImageCropDialog({super.key, required this.imageBytes});

  @override
  State<ImageCropDialog> createState() => _ImageCropDialogState();
}

class _ImageCropDialogState extends State<ImageCropDialog> {
  ui.Image? _uiImage;
  bool _isLoading = true;
  bool _isCropping = false;

  // Viewport & Cropping State
  double _scale = 1.0;
  double _startScale = 1.0;
  Offset _offset = Offset.zero;
  Offset _startFocalPoint = Offset.zero;
  Offset _lastOffset = Offset.zero;
  int _rotationTurns = 0;

  static const double _cropSize = 280.0; // Size of circular crop viewport

  @override
  void initState() {
    super.initState();
    _loadUiImage();
  }

  Future<void> _loadUiImage() async {
    try {
      final codec = await ui.instantiateImageCodec(widget.imageBytes);
      final frameInfo = await codec.getNextFrame();
      if (mounted) {
        setState(() {
          _uiImage = frameInfo.image;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading image: $e')),
        );
      }
    }
  }

  void _resetTransform() {
    setState(() {
      _scale = 1.0;
      _offset = Offset.zero;
      _rotationTurns = 0;
    });
  }

  void _rotateClockwise() {
    setState(() {
      _rotationTurns = (_rotationTurns + 1) % 4;
    });
  }

  void _rotateCounterClockwise() {
    setState(() {
      _rotationTurns = (_rotationTurns + 3) % 4;
    });
  }

  Future<void> _handleCropAndSave() async {
    final croppedBase64 = await _cropAndExport();
    if (croppedBase64 != null && mounted) {
      Navigator.pop(context, croppedBase64);
    }
  }

  Future<String?> _cropAndExport() async {
    if (_uiImage == null) return null;

    setState(() => _isCropping = true);

    try {
      const double outputSize = 512.0;
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // White background fill
      final bgPaint = Paint()..color = Colors.white;
      canvas.drawRect(const Rect.fromLTWH(0, 0, outputSize, outputSize), bgPaint);

      // Clip canvas to circle for clean profile picture avatar output
      final clipPath = Path()
        ..addOval(const Rect.fromLTWH(0, 0, outputSize, outputSize));
      canvas.clipPath(clipPath);

      final double scaleRatio = outputSize / _cropSize;

      // Move to center of output canvas
      canvas.translate(outputSize / 2, outputSize / 2);

      // Apply user pan offset
      canvas.translate(_offset.dx * scaleRatio, _offset.dy * scaleRatio);

      // Apply rotation
      if (_rotationTurns % 4 != 0) {
        canvas.rotate((_rotationTurns % 4) * (math.pi / 2));
      }

      // Base scale fits shortest side to output diameter
      final double imgW = _uiImage!.width.toDouble();
      final double imgH = _uiImage!.height.toDouble();

      // Adjust dimensions depending on 90 / 270 degree rotation
      final bool isRotated90 = (_rotationTurns % 2 != 0);
      final double effectiveW = isRotated90 ? imgH : imgW;
      final double effectiveH = isRotated90 ? imgW : imgH;

      final double baseFitScale = _cropSize / math.min(effectiveW, effectiveH);
      final double totalScale = baseFitScale * _scale * scaleRatio;

      canvas.scale(totalScale, totalScale);

      // Draw raw image centered
      final paint = Paint()
        ..isAntiAlias = true
        ..filterQuality = ui.FilterQuality.high;

      canvas.drawImage(
        _uiImage!,
        Offset(-imgW / 2, -imgH / 2),
        paint,
      );

      final picture = recorder.endRecording();
      final croppedUiImage = await picture.toImage(outputSize.toInt(), outputSize.toInt());
      final byteData = await croppedUiImage.toByteData(format: ui.ImageByteFormat.png);

      if (byteData != null) {
        final bytes = byteData.buffer.asUint8List();
        return 'data:image/jpeg;base64,${base64Encode(bytes)}';
      }
    } catch (e) {
      debugPrint('Error exporting cropped image: $e');
    } finally {
      if (mounted) setState(() => _isCropping = false);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0C20),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A153B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Crop Profile Photo',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton.icon(
              onPressed: (_isCropping || _isLoading) ? null : _handleCropAndSave,
              icon: _isCropping
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check_rounded, color: Colors.white, size: 20),
              label: Text(
                'Done',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF311B92),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF311B92)))
          : Column(
              children: [
                // Instruction hint bar
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  color: const Color(0xFF241E4D),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.touch_app_outlined, color: Colors.white70, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Drag to position • Pinch to zoom',
                        style: GoogleFonts.inter(fontSize: 12.5, color: Colors.white70),
                      ),
                    ],
                  ),
                ),

                // Central Cropping Viewport
                Expanded(
                  child: Center(
                    child: SizedBox(
                      width: double.infinity,
                      height: double.infinity,
                      child: GestureDetector(
                        onScaleStart: (details) {
                          _startScale = _scale;
                          _startFocalPoint = details.focalPoint;
                          _lastOffset = _offset;
                        },
                        onScaleUpdate: (details) {
                          setState(() {
                            _scale = (_startScale * details.scale).clamp(0.5, 4.0);
                            final delta = details.focalPoint - _startFocalPoint;
                            _offset = _lastOffset + delta;
                          });
                        },
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Raw Image Transformed
                            if (_uiImage != null)
                              Transform(
                                alignment: Alignment.center,
                                transform: Matrix4.identity()
                                  ..translate(_offset.dx, _offset.dy)
                                  ..rotateZ((_rotationTurns % 4) * (math.pi / 2))
                                  ..scale(_scale),
                                child: RawImage(
                                  image: _uiImage,
                                  fit: BoxFit.contain,
                                ),
                              ),

                            // Circular Mask Overlay
                            CustomPaint(
                              size: Size.infinite,
                              painter: _CropOverlayPainter(cropSize: _cropSize),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Controls Toolbar
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1A153B),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Zoom Slider
                      Row(
                        children: [
                          const Icon(Icons.zoom_out_rounded, color: Colors.white70, size: 20),
                          Expanded(
                            child: SliderTheme(
                              data: SliderThemeData(
                                activeTrackColor: const Color(0xFF7C4DFF),
                                inactiveTrackColor: Colors.white24,
                                thumbColor: Colors.white,
                                overlayColor: const Color(0x297C4DFF),
                                trackHeight: 3,
                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                              ),
                              child: Slider(
                                value: _scale.clamp(0.5, 4.0),
                                min: 0.5,
                                max: 4.0,
                                onChanged: (val) {
                                  setState(() => _scale = val);
                                },
                              ),
                            ),
                          ),
                          const Icon(Icons.zoom_in_rounded, color: Colors.white70, size: 20),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Tool Buttons Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildToolButton(
                            icon: Icons.rotate_left_rounded,
                            label: 'Rotate L',
                            onTap: _rotateCounterClockwise,
                          ),
                          _buildToolButton(
                            icon: Icons.rotate_right_rounded,
                            label: 'Rotate R',
                            onTap: _rotateClockwise,
                          ),
                          _buildToolButton(
                            icon: Icons.restart_alt_rounded,
                            label: 'Reset',
                            onTap: _resetTransform,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CropOverlayPainter extends CustomPainter {
  final double cropSize;

  _CropOverlayPainter({required this.cropSize});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = cropSize / 2;

    // Dark backdrop with circular cutout
    final bgPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addOval(Rect.fromCircle(center: center, radius: radius))
      ..fillType = PathFillType.evenOdd;

    final bgPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.75)
      ..style = PaintingStyle.fill;

    canvas.drawPath(bgPath, bgPaint);

    // Circular white border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    canvas.drawCircle(center, radius, borderPaint);

    // Subtle rule-of-thirds grid inside crop circle
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final third = cropSize / 3;
    final left = center.dx - radius;
    final top = center.dy - radius;

    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: radius)));

    // Vertical lines
    canvas.drawLine(Offset(left + third, top), Offset(left + third, top + cropSize), gridPaint);
    canvas.drawLine(Offset(left + third * 2, top), Offset(left + third * 2, top + cropSize), gridPaint);

    // Horizontal lines
    canvas.drawLine(Offset(left, top + third), Offset(left, top + third), gridPaint);
    canvas.drawLine(Offset(left, top + third * 2), Offset(left + cropSize, top + third * 2), gridPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CropOverlayPainter oldDelegate) {
    return oldDelegate.cropSize != cropSize;
  }
}
