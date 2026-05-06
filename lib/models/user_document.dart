class UserDocument {
  final String id;
  final String userId;
  final String docType;
  final bool uploaded;
  final String status;
  final String? filePath;
  final DateTime? uploadedAt;
  final bool isDigilocker;

  UserDocument({
    required this.id,
    required this.userId,
    required this.docType,
    required this.uploaded,
    required this.status,
    this.filePath,
    this.uploadedAt,
    this.isDigilocker = false,
  });

  factory UserDocument.fromJson(Map<String, dynamic> json) {
    // Check if verificationMetadata mentions DigiLocker or if digilockerTxId exists
    bool fromDigilocker = json['digilockerTxId'] != null || 
                          (json['verificationMetadata']?.toString().contains('DigiLocker') ?? false);

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
}
