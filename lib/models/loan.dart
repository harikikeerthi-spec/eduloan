class Loan {
  final String id;
  final String userId;
  final String applicantName;
  final String phoneNumber;
  final String email;
  final String institute;
  final String course;
  final String bank;
  final String loanType;
  final double amount;
  final int tenure;
  final String? purpose;
  final String status;
  final int progress;
  final DateTime date;
  final DateTime updatedAt;

  Loan({
    required this.id,
    required this.userId,
    required this.applicantName,
    required this.phoneNumber,
    required this.email,
    required this.institute,
    required this.course,
    required this.bank,
    required this.loanType,
    required this.amount,
    required this.tenure,
    this.purpose,
    required this.status,
    required this.progress,
    required this.date,
    required this.updatedAt,
  });

  factory Loan.fromJson(Map<String, dynamic> json) {
    return Loan(
      id: json['id'],
      userId: json['userId'],
      applicantName: json['applicantName'],
      phoneNumber: json['phoneNumber'],
      email: json['email'],
      institute: json['institute'],
      course: json['course'],
      bank: json['bank'],
      loanType: json['loanType'],
      amount: (json['amount'] as num).toDouble(),
      tenure: json['tenure'],
      purpose: json['purpose'],
      status: json['status'],
      progress: json['progress'],
      date: DateTime.parse(json['date']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'applicantName': applicantName,
      'phoneNumber': phoneNumber,
      'email': email,
      'institute': institute,
      'course': course,
      'bank': bank,
      'loanType': loanType,
      'amount': amount,
      'tenure': tenure,
      'purpose': purpose,
      'status': status,
      'progress': progress,
      'date': date.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
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
}
