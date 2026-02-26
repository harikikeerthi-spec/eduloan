import 'package:flutter/material.dart';

class ManualUploadModal extends StatefulWidget {
  final VoidCallback onUploadComplete;

  const ManualUploadModal({super.key, required this.onUploadComplete});

  @override
  State<ManualUploadModal> createState() => _ManualUploadModalState();
}

class _ManualUploadModalState extends State<ManualUploadModal> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Manually upload documents',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.grey),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'You can upload a single file if it contains both front and back side of the following documents.',
            style: TextStyle(
              fontSize: 15,
              color: Color(0xFF4B5563),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),

          _buildSectionHeader('1. Upload PAN card'),
          const SizedBox(height: 12),
          _buildUploadBox('PAN Card', isLarge: true),

          const SizedBox(height: 24),
          _buildSectionHeader('2. Upload AADHAR card'),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildUploadBox('Front side'),
              const SizedBox(width: 16),
              _buildUploadBox('Back side'),
            ],
          ),

          const SizedBox(height: 24),
          _buildSectionHeader('3. Upload Passport scan'),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildUploadBox('Front side'),
              const SizedBox(width: 16),
              _buildUploadBox('Back side'),
            ],
          ),

          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                widget.onUploadComplete();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6200EA), // Primary Purple
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Upload and proceed',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Color(0xFF374151),
      ),
    );
  }

  Widget _buildUploadBox(String label, {bool isLarge = false}) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          // Trigger file picker or simulated upload
        },
        child: Container(
          height: isLarge ? 120 : 100,
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add, color: Color(0xFF3B82F6), size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
