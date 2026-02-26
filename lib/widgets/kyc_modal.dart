import 'package:flutter/material.dart';
import 'manual_upload_modal.dart';

class KycModal extends StatelessWidget {
  final VoidCallback onManualUpload;

  const KycModal({super.key, required this.onManualUpload});

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
                'Complete your KYC',
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
          const SizedBox(height: 20),
          const Text(
            'Connect with DigiLocker for seamless KYC and profile integration.',
            style: TextStyle(
              fontSize: 15,
              color: Color(0xFF4B5563),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Alternatively, you can manually upload the following documents',
            style: TextStyle(
              fontSize: 15,
              color: Color(0xFF4B5563),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          _buildDocItem('1. PAN Card'),
          _buildDocItem('2. AADHAR Card (1 file, front and back)'),
          _buildDocItem('3. Passport (1 file, front and back)'),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Show manual upload modal
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) =>
                      ManualUploadModal(onUploadComplete: onManualUpload),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF3E8FF), // Light purple
                foregroundColor: const Color(0xFF7E22CE), // Dark purple text
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Manually upload documents',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
      ),
    );
  }
}
