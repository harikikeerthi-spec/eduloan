const fs = require('fs');

const path = 'c:/flutter/projects/Vidhyaloan/lib/pages/apply_loan_page.dart';
let content = fs.readFileSync(path, 'utf-8');

// 1. Imports
content = content.replace(/import 'package:file_picker\/file_picker\.dart';\r?\n/, '');
content = content.replace(/import '\.\.\/services\/digilocker_service\.dart';\r?\n/, '');
content = content.replace(/import 'digilocker_auth_page\.dart';\r?\n/, '');

// 2. State variables
content = content.replace(/  bool _isDigilockerVerified = false;\r?\n  Map<String, dynamic>\? _digilockerData;\r?\n  List<PlatformFile> _manuallyUploadedFiles = \[\];\r?\n\r?\n/, '');

// 3. _verifyWithDigilocker
content = content.replace(/  Future<void> _verifyWithDigilocker\(\) async \{[\s\S]*?\r?\n  \}\r?\n\r?\n  final List<String> _lendingPartners/, '  final List<String> _lendingPartners');

// 4. _submitApplication
content = content.replace(/\|\|\r?\n        !_validateStep\(4\)\) \{\r?\n      return;/, ') {\n      return;');

// 5. _validateStep
content = content.replace(/    \} else if \(step == 4\) \{\r?\n      if \(!_isDigilockerVerified && _manuallyUploadedFiles\.isEmpty\) \{\r?\n        _showError\('Please verify via DigiLocker or upload documents manually'\);\r?\n        return false;\r?\n      \}\r?\n    \}\r?\n    return true;/, '    }\n    return true;');

// 6. onStepContinue
content = content.replace(/if \(_currentStep < 4\) \{\r?\n                          setState\(\(\) => _currentStep \+= 1\);/, 'if (_currentStep < 3) {\n                          setState(() => _currentStep += 1);');

// 7. controlsBuilder
content = content.replace(/_currentStep == 4\r?\n                                      \? 'Submit Application'/, "_currentStep == 3\n                                      ? 'Submit Application'");

// 8. Step 4
content = content.replace(/                      Step\(\r?\n                        title: const Text\(\r?\n                          'Upload Documents',[\s\S]*?isActive: _currentStep >= 4,\r?\n                      \),\r?\n/, '');

fs.writeFileSync(path, content, 'utf-8');
console.log('Done');
