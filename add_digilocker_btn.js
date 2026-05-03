const fs = require('fs');

const path = 'c:/flutter/projects/Vidhyaloan/lib/pages/my_loans_page.dart';
let content = fs.readFileSync(path, 'utf-8');

// 1. Add imports
if (!content.includes('digilocker_auth_page.dart')) {
  content = content.replace(
    /import 'apply_loan_page\.dart';/,
    "import 'apply_loan_page.dart';\nimport 'digilocker_auth_page.dart';\nimport '../services/digilocker_service.dart';"
  );
}

// 2. Add button above UPLOAD FROM VAULT
const uploadBtnTarget = `              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DocumentVaultPage(),
                      ),
                    ).then((_) => _fetchLoans());
                  },`;

const digilockerBtn = `              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _verifyWithDigilocker,
                  icon: const Icon(Icons.security, color: Color(0xFF311B92)),
                  label: const Text(
                    'FETCH FROM DIGILOCKER',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF311B92),
                    side: const BorderSide(color: Color(0xFF311B92)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
`;

if (!content.includes('FETCH FROM DIGILOCKER')) {
  content = content.replace(uploadBtnTarget, digilockerBtn + uploadBtnTarget);
}

// 3. Add _verifyWithDigilocker method
const methodTarget = `  String _formatDate(DateTime date) {`;
const verifyMethod = `  Future<void> _verifyWithDigilocker() async {
    final code = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const DigilockerAuthPage(),
      ),
    );

    if (code != null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Color(0xFF311B92)),
        ),
      );

      try {
        final service = DigilockerService();
        final result = await service.verifyDigilocker(code as String);
        
        Navigator.pop(context); // Close loading dialog

        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('DigiLocker Verification Successful!'),
              backgroundColor: Color(0xFF10B981),
            ),
          );
          _fetchLoans();
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Verification failed: $e'),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

`;

if (!content.includes('_verifyWithDigilocker()')) {
  content = content.replace(methodTarget, verifyMethod + methodTarget);
}

fs.writeFileSync(path, content, 'utf-8');
console.log('Done');
