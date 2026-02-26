import 'package:flutter/material.dart';

class AvatarSelectionDialog extends StatelessWidget {
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
            'Select an icon that reflects your personality',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 32),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: avatars.length,
            itemBuilder: (context, index) {
              final avatar = avatars[index];
              final isSelected = currentAvatar == avatar['name'];

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
