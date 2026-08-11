import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'image_crop_dialog.dart';

class AvatarSelectionDialog extends StatefulWidget {
  final String? currentAvatar;

  const AvatarSelectionDialog({super.key, this.currentAvatar});

  static const List<Map<String, dynamic>> avatars = [
    {'icon': Icons.face_6, 'color': Color(0xFF311B92), 'name': 'male_1'},
    {'icon': Icons.face_2, 'color': Color(0xFFD32F2F), 'name': 'female_1'},
    {'icon': Icons.face, 'color': Color(0xFF388E3C), 'name': 'male_2'},
    {'icon': Icons.face_3, 'color': Color(0xFFF57C00), 'name': 'female_2'},
    {'icon': Icons.person_outline, 'color': Color(0xFF00796B), 'name': 'male_3'},
    {'icon': Icons.person_2_outlined, 'color': Color(0xFF1976D2), 'name': 'female_3'},
    {'icon': Icons.account_circle, 'color': Color(0xFF7B1FA2), 'name': 'male_4'},
    {'icon': Icons.account_circle_outlined, 'color': Color(0xFFFBC02D), 'name': 'female_4'},
  ];

  @override
  State<AvatarSelectionDialog> createState() => _AvatarSelectionDialogState();
}

class _AvatarSelectionDialogState extends State<AvatarSelectionDialog> {
  bool _isPicking = false;

  Future<void> _pickImage(ImageSource source) async {
    setState(() => _isPicking = true);
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 90,
      );

      if (image != null && mounted) {
        final bytes = await image.readAsBytes();
        if (mounted) {
          // Launch interactive crop dialog
          final croppedBase64 = await Navigator.push<String>(
            context,
            MaterialPageRoute(
              builder: (context) => ImageCropDialog(imageBytes: bytes),
            ),
          );

          if (croppedBase64 != null && mounted) {
            Navigator.pop(context, croppedBase64);
            return;
          }
        }
      }
      if (mounted) {
        setState(() => _isPicking = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isPicking = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _cropCurrentPhoto() async {
    if (widget.currentAvatar == null || !widget.currentAvatar!.startsWith('data:image/')) return;
    try {
      final base64Str = widget.currentAvatar!.split(',').last;
      final bytes = base64Decode(base64Str);
      final croppedBase64 = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (context) => ImageCropDialog(imageBytes: bytes),
        ),
      );

      if (croppedBase64 != null && mounted) {
        Navigator.pop(context, croppedBase64);
      }
    } catch (e) {
      debugPrint('Error re-cropping photo: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasCustomPhoto = widget.currentAvatar != null &&
        widget.currentAvatar!.startsWith('data:image/');

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Choose Your Profile Photo',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Upload a photo, crop it to fit, or choose an avatar',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),

          // Re-crop option if user has custom photo
          if (hasCustomPhoto) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _cropCurrentPhoto,
                icon: const Icon(Icons.crop_rounded, color: Colors.white),
                label: const Text(
                  'Crop / Adjust Current Photo ✂️',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF311B92),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Custom Photo Buttons
          if (_isPicking)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(color: Color(0xFF311B92)),
            )
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Camera'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Gallery'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: AvatarSelectionDialog.avatars.length,
            itemBuilder: (context, index) {
              final avatar = AvatarSelectionDialog.avatars[index];
              final isSelected = widget.currentAvatar == avatar['name'];

              return InkWell(
                onTap: () => Navigator.pop(context, avatar['name']),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  decoration: BoxDecoration(
                    color: avatar['color'].withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(color: avatar['color'], width: 3)
                        : null,
                  ),
                  child: Icon(avatar['icon'], color: avatar['color'], size: 32),
                ),
              );
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

