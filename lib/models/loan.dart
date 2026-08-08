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
    final statusLower = status.toLowerCase();
    final stageLower = stage.toLowerCase();
    final bool isSentToBank = statusLower == 'submitted_to_bank' ||
        statusLower == 'file_logged' ||
        statusLower == 'under_bank_review' ||
        statusLower == 'query_raised' ||
        statusLower == 'conditional_sanction' ||
        statusLower == 'partial_sanction' ||
        statusLower == 'counter_offer' ||
        statusLower == 'approved' ||
        statusLower == 'sanctioned' ||
        statusLower == 'disbursement_confirmed' ||
        statusLower == 'closed' ||
        stageLower == 'credit_check' ||
        stageLower == 'bank_review' ||
        stageLower == 'sanction' ||
        stageLower == 'sanctioned' ||
        stageLower == 'disbursement' ||
        stageLower == 'disbursed';

    return isSentToBank ? bank : 'Matching Lenders...';
  }
}
