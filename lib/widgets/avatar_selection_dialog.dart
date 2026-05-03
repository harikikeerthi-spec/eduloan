import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AvatarSelectionDialog extends StatefulWidget {
  final String? currentAvatar;

  const AvatarSelectionDialog({super.key, this.currentAvatar});

  static const List<Map<String, dynamic>> avatars = [
    {'icon': Icons.person, 'color': Color(0xFF311B92), 'name': 'standard'},
    {'icon': Icons.face, 'color': Color(0xFFD32F2F), 'name': 'face'},
    {'icon': Icons.mood, 'color': Color(0xFF388E3C), 'name': 'mood'},
    {'icon': Icons.pets, 'color': Color(0xFFF57C00), 'name': 'pets'},
    {'icon': Icons.eco, 'color': Color(0xFF00796B), 'name': 'eco'},
    {'icon': Icons.rocket_launch, 'color': Color(0xFF1976D2), 'name': 'rocket'},
    {'icon': Icons.auto_awesome, 'color': Color(0xFF7B1FA2), 'name': 'sparkle'},
    {'icon': Icons.lightbulb, 'color': Color(0xFFFBC02D), 'name': 'light'},
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
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 70,
      );

      if (image != null && mounted) {
        final bytes = await image.readAsBytes();
        final base64String = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        Navigator.pop(context, base64String);
      } else if (mounted) {
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

  @override
  Widget build(BuildContext context) {
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
            'Choose Your Avatar',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select an icon or upload your own photo',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
          
          // Custom Photo Buttons
          if (_isPicking)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
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
