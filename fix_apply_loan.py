import re

with open('c:/flutter/projects/Vidhyaloan/lib/pages/apply_loan_page.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Imports
content = re.sub(r"import 'package:file_picker/file_picker\.dart';\n", '', content)
content = re.sub(r"import '\.\./services/digilocker_service\.dart';\n", '', content)
content = re.sub(r"import 'digilocker_auth_page\.dart';\n", '', content)

# 2. State variables
content = re.sub(r"  bool _isDigilockerVerified = false;\n  Map<String, dynamic>\? _digilockerData;\n  List<PlatformFile> _manuallyUploadedFiles = \[\];\n\n", '', content)

# 3. _verifyWithDigilocker
content = re.sub(r"  Future<void> _verifyWithDigilocker\(\) async \{.*?\n  \}\n\n  final List<String> _lendingPartners", "  final List<String> _lendingPartners", content, flags=re.DOTALL)

# 4. _submitApplication
content = re.sub(r"\|\|\n        !_validateStep\(4\)\) \{\n      return;", ") {\n      return;", content)

# 5. _validateStep
content = re.sub(r"    \} else if \(step == 4\) \{\n      if \(!_isDigilockerVerified && _manuallyUploadedFiles\.isEmpty\) \{\n        _showError\('Please verify via DigiLocker or upload documents manually'\);\n        return false;\n      \}\n    \}\n    return true;", "    }\n    return true;", content)

# 6. onStepContinue
content = re.sub(r"if \(_currentStep < 4\) \{\n                          setState\(\(\) => _currentStep \+= 1\);", "if (_currentStep < 3) {\n                          setState(() => _currentStep += 1);", content)

# 7. controlsBuilder
content = re.sub(r"_currentStep == 4\n                                      \? 'Submit Application'", "_currentStep == 3\n                                      ? 'Submit Application'", content)

# 8. Step 4
content = re.sub(r"                      Step\(\n                        title: const Text\(\n                          'Upload Documents',.*?isActive: _currentStep >= 4,\n                      \),\n", '', content, flags=re.DOTALL)


with open('c:/flutter/projects/Vidhyaloan/lib/pages/apply_loan_page.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print('Done')
