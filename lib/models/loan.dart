import 'application_document.dart';

class Loan {
  final String id;
  final String userId;
  final String? applicationNumber;
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String email;
  final String? universityName;
  final String? targetCountry;
  final String? courseName;
  final String? fieldOfStudy;
  final String? admissionStatus;
  final String bank;
  final String loanType;
  final double amount;
  final int tenure;
  final String? purpose;
  final String status;
  final String stage;
  final int progress;
  final DateTime date;
  final DateTime updatedAt;
  final String? counselorName;
  final String? counselorPhone;
  final String? counselorEmail;
  final String? fatherName;
  final String? fatherPhone;
  final String? fatherEmail;
  final String? motherName;
  final String? motherPhone;
  final String? motherEmail;
  final String? city;
  final String? pincode;
  final String? country;
  final bool hasCollateral;
  final String? collateralDetails;
  final bool hasCoApplicant;
  final String? coApplicantName;
  final String? coApplicantRelation;
  final String? coApplicantPhone;
  final String? coApplicantEmail;
  final double? coApplicantIncome;
  final List<ApplicationDocument> documents;

  Loan({
    required this.id,
    required this.userId,
    this.applicationNumber,
    this.firstName,
    this.lastName,
    this.phone,
    required this.email,
    this.universityName,
    this.targetCountry,
    this.courseName,
    required this.bank,
    required this.loanType,
    required this.amount,
    required this.tenure,
    this.purpose,
    this.fieldOfStudy,
    this.admissionStatus,
    required this.status,
    required this.stage,
    required this.progress,
    required this.date,
    required this.updatedAt,
    this.counselorName,
    this.counselorPhone,
    this.counselorEmail,
    this.fatherName,
    this.fatherPhone,
    this.fatherEmail,
    this.motherName,
    this.motherPhone,
    this.motherEmail,
    this.city,
    this.pincode,
    this.country,
    this.hasCollateral = false,
    this.collateralDetails,
    this.hasCoApplicant = false,
    this.coApplicantName,
    this.coApplicantRelation,
    this.coApplicantPhone,
    this.coApplicantEmail,
    this.coApplicantIncome,
    this.documents = const [],
  });

  String get fullName {
    final fn = firstName ?? '';
    final ln = lastName ?? '';
    final name = '$fn $ln'.trim();
    return name.isEmpty ? 'Student Applicant' : name;
  }

  String get phoneNumber => phone ?? '';

  int getEffectiveProgress({bool hasUploadedDocs = false}) {
    int p = progress;
    final st = status.toLowerCase().trim();
    final sg = stage.toLowerCase().trim();

    if (st == 'disbursed' ||
        st == 'disbursement_confirmed' ||
        st == 'disbursed_to_university' ||
        st == 'closed' ||
        sg == 'disbursement' ||
        sg == 'disbursed') {
      return 100;
    }
    if (st == 'sanctioned' ||
        st == 'approved' ||
        st == 'conditional_sanction' ||
        st == 'partial_sanction' ||
        st == 'counter_offer' ||
        sg == 'sanction' ||
        sg == 'sanctioned') {
      return p > 95 ? p : 95;
    }
    if (st == 'under_bank_review' ||
        st == 'bank_review' ||
        sg == 'bank_review' ||
        sg == 'under_bank_review') {
      return p > 90 ? p : 90;
    }
    if (st == 'credit_check' ||
        st == 'file_logged' ||
        st == 'query_raised' ||
        st == 'under_review' ||
        sg == 'credit_check' ||
        sg == 'file_logged' ||
        sg == 'query_raised' ||
        sg == 'verification' ||
        sg == 'review') {
      return p > 75 ? p : 75;
    }
    if (st == 'submitted_to_bank' ||
        st == 'submit_to_bank' ||
        sg == 'submitted_to_bank' ||
        sg == 'submit_to_bank') {
      return p > 50 ? p : 50;
    }
    if (hasUploadedDocs ||
        st == 'documents_verified' ||
        st == 'staff_verified' ||
        sg == 'documents_verified' ||
        sg == 'documents_approved') {
      return p > 40 ? p : 40;
    }
    if (st == 'submitted' ||
        st == 'application_submitted' ||
        st == 'pending' ||
        st == 'docs_received' ||
        st == 'documents_uploaded' ||
        sg == 'application_submitted' ||
        sg == 'submitted' ||
        sg == 'pending' ||
        sg == 'documents_uploaded') {
      return p >= 25 ? p : 25;
    }
    if (st == 'created' || sg == 'created' || st == 'draft') {
      return p > 0 ? p : 10;
    }
    return p >= 25 ? p : 25;
  }

  int getEffectiveStageIndex({bool hasUploadedDocs = false}) {
    final effProgress = getEffectiveProgress(hasUploadedDocs: hasUploadedDocs);
    if (effProgress >= 100) return 7; // Disbursed
    if (effProgress >= 95) return 6; // Sanction
    if (effProgress >= 90) return 5; // Review
    if (effProgress >= 75) return 4; // Credit Check
    if (effProgress >= 50) return 3; // Submit to Bank
    if (effProgress >= 40 || hasUploadedDocs) return 2; // Documents
    if (effProgress >= 25) return 1; // Submitted
    return 0; // Created
  }

  String currentStageLabel({bool hasUploadedDocs = false}) {
    final idx = getEffectiveStageIndex(hasUploadedDocs: hasUploadedDocs);
    const stageLabels = [
      'CREATED',
      'SUBMITTED',
      'DOCUMENTS',
      'SUBMIT TO BANK',
      'CREDIT CHECK',
      'REVIEW',
      'SANCTION',
      'DISBURSED',
    ];
    if (idx >= 0 && idx < stageLabels.length) {
      return stageLabels[idx];
    }
    return 'DOCUMENTS';
  }

  bool get hasAssignedStaff {
    if (counselorName == null) return false;
    final name = counselorName!.trim().toLowerCase();
    if (name.isEmpty ||
        name.contains('support') ||
        name.contains('priya') ||
        name.contains('rajesh') ||
        name.contains('ananya') ||
        name.contains('vikram') ||
        name.contains('counselor') ||
        name.contains('specialist')) {
      return false;
    }
    return true;
  }

  String get assignedStaffDisplayName {
    if (hasAssignedStaff) {
      return counselorName!.trim();
    }
    return 'Assigning Loan Specialist...';
  }

  String get assignedStaffPhone {
    if (hasAssignedStaff &&
        counselorPhone != null &&
        counselorPhone!.trim().isNotEmpty) {
      return counselorPhone!.trim();
    }
    return 'Will be allocated shortly';
  }

  String get assignedStaffEmail {
    if (hasAssignedStaff &&
        counselorEmail != null &&
        counselorEmail!.trim().isNotEmpty) {
      return counselorEmail!.trim();
    }
    return 'support@vidyaloans.in';
  }

  int get effectiveProgress => getEffectiveProgress();
  int get effectiveStageIndex => getEffectiveStageIndex();

  static DateTime _parseDate(dynamic val) {
    if (val == null) return DateTime.now();
    if (val is DateTime) return val.toLocal();
    final s = val.toString().trim();
    if (s.isEmpty) return DateTime.now();
    try {
      if (s.endsWith('Z') ||
          s.contains('+') ||
          RegExp(r'-\d{2}:\d{2}$').hasMatch(s)) {
        return DateTime.parse(s).toLocal();
      }
      return DateTime.parse('${s}Z').toLocal();
    } catch (_) {
      try {
        return DateTime.parse(s).toLocal();
      } catch (_) {
        return DateTime.now();
      }
    }
  }

  factory Loan.fromJson(Map<String, dynamic> json) {
    var docsList = <ApplicationDocument>[];
    if (json['documents'] != null) {
      docsList = (json['documents'] as List)
          .map((doc) => ApplicationDocument.fromJson(doc))
          .toList();
    }

    return Loan(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      applicationNumber: json['applicationNumber']?.toString(),
      firstName: json['firstName'],
      lastName: json['lastName'],
      phone: json['phone'],
      email: json['email']?.toString() ?? '',
      universityName: json['universityName'],
      targetCountry: json['targetCountry'] ?? json['country'],
      courseName: json['courseName'],
      bank: json['bank']?.toString() ?? 'Matching Lenders...',
      loanType: json['loanType']?.toString() ?? 'Education Loan',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      tenure: json['tenure'] != null
          ? int.tryParse(json['tenure'].toString()) ?? 0
          : 0,
      purpose: json['purpose'],
      status: json['status']?.toString() ?? 'pending',
      stage: json['stage']?.toString() ?? 'application_submitted',
      progress: json['progress'] != null
          ? int.tryParse(json['progress'].toString()) ?? 0
          : 0,
      date: _parseDate(
        json['submittedAt'] ?? json['date'] ?? json['createdAt'],
      ),
      updatedAt: _parseDate(
        json['updatedAt'] ?? json['submittedAt'] ?? json['date'],
      ),
      counselorName: json['counselorName']?.toString(),
      counselorPhone: json['counselorPhone']?.toString(),
      counselorEmail: json['counselorEmail']?.toString(),
      fatherName: json['fatherName']?.toString(),
      fatherPhone: json['fatherPhone']?.toString(),
      fatherEmail: json['fatherEmail']?.toString(),
      motherName: json['motherName']?.toString(),
      motherPhone: json['motherPhone']?.toString(),
      motherEmail: json['motherEmail']?.toString(),
      city: json['city']?.toString(),
      pincode: json['pincode']?.toString(),
      country: json['country']?.toString(),
      fieldOfStudy: json['fieldOfStudy']?.toString(),
      admissionStatus: json['admissionStatus']?.toString(),
      hasCollateral: json['hasCollateral'] ?? false,
      collateralDetails: json['collateralDetails']?.toString(),
      hasCoApplicant: json['hasCoApplicant'] ?? false,
      coApplicantName: json['coApplicantName']?.toString(),
      coApplicantRelation: json['coApplicantRelation']?.toString(),
      coApplicantPhone: json['coApplicantPhone']?.toString(),
      coApplicantEmail: json['coApplicantEmail']?.toString(),
      coApplicantIncome: (json['coApplicantIncome'] as num?)?.toDouble(),
      documents: docsList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'applicationNumber': applicationNumber,
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'email': email,
      'universityName': universityName,
      'targetCountry': targetCountry,
      'courseName': courseName,
      'bank': bank,
      'loanType': loanType,
      'amount': amount,
      'tenure': tenure,
      'purpose': purpose,
      'status': status,
      'stage': stage,
      'progress': progress,
      'date': date.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'counselorName': counselorName,
      'counselorPhone': counselorPhone,
      'counselorEmail': counselorEmail,
      'fieldOfStudy': fieldOfStudy,
      'admissionStatus': admissionStatus,
      'documents': documents.map((doc) => doc.toJson()).toList(),
    };
  }

  String get statusDisplay {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending Review';
      case 'processing':
        return 'Under Processing';
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      default:
        return status;
    }
  }

  String get displayBank {
    final b = bank.toLowerCase().trim();
    final st = status.toLowerCase().trim();
    final sg = stage.toLowerCase().trim();

    if (b.isEmpty ||
        b == 'any bank' ||
        b == 'any' ||
        b == 'unknown bank' ||
        b == 'not assigned' ||
        b == 'all banks' ||
        b == 'matching lenders' ||
        b == 'matching lenders...' ||
        b == 'pending bank assignment' ||
        b.contains('pending') ||
        b.contains('matching') ||
        st == 'submitted' ||
        st == 'application_submitted' ||
        st == 'pending' ||
        st == 'draft' ||
        sg == 'application_submitted' ||
        sg == 'submitted' ||
        sg == 'created' ||
        sg == 'pending') {
      return 'Matching Lenders...';
    }
    return bank;
  }
}
