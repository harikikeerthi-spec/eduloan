class ApplicationDocument {
  final String id;
  final String applicationId;
  final String docType;
  final String docName;
  final String fileName;
  final String filePath;
  final int? fileSize;
  final String? mimeType;
  final String status;
  final DateTime? verifiedAt;
  final String? verifiedBy;
  final String? rejectionReason;
  final DateTime? expiryDate;
  final bool isRequired;
  final DateTime uploadedAt;
  final DateTime updatedAt;

  ApplicationDocument({
    required this.id,
    required this.applicationId,
    required this.docType,
    required this.docName,
    required this.fileName,
    required this.filePath,
    this.fileSize,
    this.mimeType,
    required this.status,
    this.verifiedAt,
    this.verifiedBy,
    this.rejectionReason,
    this.expiryDate,
    required this.isRequired,
    required this.uploadedAt,
    required this.updatedAt,
  });

  factory ApplicationDocument.fromJson(Map<String, dynamic> json) {
    return ApplicationDocument(
      id: json['id']?.toString() ?? '',
      applicationId: json['applicationId']?.toString() ?? '',
      docType: json['docType']?.toString() ?? '',
      docName: json['docName']?.toString() ?? 'Unnamed Document',
      fileName: json['fileName']?.toString() ?? '',
      filePath: json['filePath']?.toString() ?? '',
      fileSize: json['fileSize'],
      mimeType: json['mimeType'],
      status: json['status']?.toString() ?? 'pending',
      verifiedAt: json['verifiedAt'] != null
          ? DateTime.tryParse(json['verifiedAt'].toString())
          : null,
      verifiedBy: json['verifiedBy'],
      rejectionReason: json['rejectionReason'],
      expiryDate: json['expiryDate'] != null
          ? DateTime.tryParse(json['expiryDate'].toString())
          : null,
      isRequired: json['isRequired'] ?? true,
      uploadedAt: json['uploadedAt'] != null
          ? DateTime.parse(json['uploadedAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'applicationId': applicationId,
      'docType': docType,
      'docName': docName,
      'fileName': fileName,
      'filePath': filePath,
      'fileSize': fileSize,
      'mimeType': mimeType,
      'status': status,
      'verifiedAt': verifiedAt?.toIso8601String(),
      'verifiedBy': verifiedBy,
      'rejectionReason': rejectionReason,
      'expiryDate': expiryDate?.toIso8601String(),
      'isRequired': isRequired,
      'uploadedAt': uploadedAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  bool get isUploaded => filePath.isNotEmpty;
}
