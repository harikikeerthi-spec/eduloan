class UserDocument {
  final String id;
  final String userId;
  final String docType;
  final bool uploaded;
  final String status;
  final String? filePath;
  final DateTime? uploadedAt;
  final bool isDigilocker;
  final String? rejectionReason;
  final Map<String, dynamic>? verificationMetadata;

  UserDocument({
    required this.id,
    required this.userId,
    required this.docType,
    required this.uploaded,
    required this.status,
    this.filePath,
    this.uploadedAt,
    this.isDigilocker = false,
    this.rejectionReason,
    this.verificationMetadata,
  });

  factory UserDocument.fromJson(Map<String, dynamic> json) {
    // Check if verificationMetadata mentions DigiLocker or if digilockerTxId exists
    bool fromDigilocker = json['digilockerTxId'] != null || 
                          (json['verificationMetadata']?.toString().contains('DigiLocker') ?? false);

    String? reason = json['rejectionReason']?.toString();
    Map<String, dynamic>? meta;
    if (json['verificationMetadata'] != null) {
      if (json['verificationMetadata'] is Map) {
        meta = Map<String, dynamic>.from(json['verificationMetadata']);
      }
    }

    if (reason == null && meta != null) {
      reason = meta['rejectionReason']?.toString();
    }

    return UserDocument(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      docType: json['docType']?.toString() ?? '',
      uploaded: json['uploaded'] ?? false,
      status: json['status']?.toString() ?? 'pending',
      filePath: json['filePath']?.toString(),
      uploadedAt: json['uploadedAt'] != null
          ? DateTime.tryParse(json['uploadedAt'].toString())
          : null,
      isDigilocker: fromDigilocker,
      rejectionReason: reason,
      verificationMetadata: meta,
    );
  }

  String get displayName {
    // Convert snake_case or camelCase to Title Case
    // e.g. "aadhar_card" -> "Aadhar Card"
    return docType
        .replaceAll('_', ' ')
        .split(' ')
        .map(
          (str) => str.isNotEmpty
              ? '${str[0].toUpperCase()}${str.substring(1).toLowerCase()}'
              : '',
        )
        .join(' ');
  }

  /// Extracts the document number (PAN, Aadhar, Passport, Roll No) from AI OCR metadata.
  String? get extractedNumber {
    if (verificationMetadata == null) return null;

    final List<Map<String, dynamic>> mapsToCheck = [];

    void addCandidate(dynamic obj) {
      if (obj == null) return;
      if (obj is Map<String, dynamic>) {
        mapsToCheck.add(obj);
      } else if (obj is Map) {
        try {
          mapsToCheck.add(Map<String, dynamic>.from(obj));
        } catch (_) {}
      }
    }

    addCandidate(verificationMetadata);

    final details = verificationMetadata!['details'];
    addCandidate(details);

    if (details is Map) {
      final detMap = Map<String, dynamic>.from(details);
      addCandidate(detMap['extractedFields']);
      addCandidate(detMap['extracted_fields']);
      addCandidate(detMap['extracted_data']);
      addCandidate(detMap['extractedData']);
      addCandidate(detMap['ocrResult']);
    }

    addCandidate(verificationMetadata!['extractedFields']);
    addCandidate(verificationMetadata!['extracted_fields']);
    addCandidate(verificationMetadata!['extracted_data']);
    addCandidate(verificationMetadata!['extractedData']);
    addCandidate(verificationMetadata!['ocrResult']);
    addCandidate(verificationMetadata!['verification']);

    for (var data in mapsToCheck) {
      final val = data['pan_number'] ??
          data['panNumber'] ??
          data['pan'] ??
          data['aadhaar_number'] ??
          data['aadhar_number'] ??
          data['aadhaarNumber'] ??
          data['aadharNumber'] ??
          data['aadhaar'] ??
          data['aadhar'] ??
          data['passport_number'] ??
          data['passportNumber'] ??
          data['passport'] ??
          data['roll_number'] ??
          data['rollNumber'] ??
          data['registration_number'] ??
          data['registrationNumber'] ??
          data['id_number'] ??
          data['idNumber'] ??
          data['document_number'] ??
          data['documentNumber'] ??
          data['number'];
      if (val != null && val.toString().trim().isNotEmpty) {
        return val.toString().trim();
      }
    }
    return null;
  }
}
