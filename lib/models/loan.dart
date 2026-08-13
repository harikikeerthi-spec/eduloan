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
      return 95;
    }
    if (st == 'under_bank_review' ||
        st == 'bank_review' ||
        sg == 'bank_review' ||
        sg == 'under_bank_review') {
      return 90;
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
      return 75;
    }
    if (st == 'submitted_to_bank' ||
        st == 'submit_to_bank' ||
        st == 'staff_verified' ||
        sg == 'submitted_to_bank' ||
        sg == 'submit_to_bank') {
      return 50;
    }
    if (hasUploadedDocs ||
        st == 'documents_verified' ||
        st == 'staff_verified' ||
        st == 'submitted_to_bank' ||
        st == 'submit_to_bank' ||
        sg == 'documents_verified' ||
        sg == 'documents_approved') {
      return 40;
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
      return 25;
    }
    if (st == 'created' || sg == 'created' || st == 'draft') {
      return 10;
    }
    return progress > 0 ? progress : 25;
  }

  int getEffectiveStageIndex({bool hasUploadedDocs = false}) {
    final st = status.toLowerCase().trim();
    final sg = stage.toLowerCase().trim();

    if (st == 'disbursed' ||
        st == 'disbursement_confirmed' ||
        st == 'disbursed_to_university' ||
        st == 'closed' ||
        sg == 'disbursement' ||
        sg == 'disbursed') {
      return 7;
    }
    if (st == 'sanctioned' ||
        st == 'approved' ||
        st == 'conditional_sanction' ||
        st == 'partial_sanction' ||
        st == 'counter_offer' ||
        sg == 'sanction' ||
        sg == 'sanctioned') {
      return 6;
    }
    if (st == 'under_bank_review' ||
        st == 'bank_review' ||
        sg == 'bank_review' ||
        sg == 'under_bank_review') {
      return 5;
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
      return 4;
    }
    if (st == 'submitted_to_bank' ||
        st == 'submit_to_bank' ||
        st == 'staff_verified' ||
        sg == 'submitted_to_bank' ||
        sg == 'submit_to_bank') {
      return 3;
    }
    if (hasUploadedDocs ||
        st == 'documents_verified' ||
        st == 'staff_verified' ||
        st == 'submitted_to_bank' ||
        st == 'submit_to_bank' ||
        sg == 'documents_verified' ||
        sg == 'documents_approved') {
      return 2;
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
      return 1;
    }
    return 0;
  }

  String currentStageLabel({bool hasUploadedDocs = false}) {
    final idx = getEffectiveStageIndex(hasUploadedDocs: hasUploadedDocs);
    const stageLabels = [
      'Created',
      'Submitted',
      'Documents',
      'Submit to Bank',
      'Credit Check',
      'Bank Review',
      'Sanction',
      'Disbursed',
    ];
    if (idx >= 0 && idx < stageLabels.length) {
      return stageLabels[idx];
    }
    return 'Submitted';
  }

  int get effectiveProgress => getEffectiveProgress();
  int get effectiveStageIndex => getEffectiveStageIndex();

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
      bank: json['bank']?.toString() ?? 'Unknown Bank',
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
      date: json['date'] != null
          ? DateTime.parse(json['date'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
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
    if (b.isEmpty ||
        b == 'any bank' ||
        b == 'any' ||
        b == 'unknown bank' ||
        b == 'not assigned' ||
        b == 'all banks' ||
        b == 'pending bank assignment' ||
        b.contains('pending')) {
      return 'Matching Lenders...';
    }
    return bank;
  }
}
