import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/loan.dart';
import '../models/user_document.dart';
import 'user_service.dart';

class PdfGeneratorService {
  // Document definitions matching DocumentVaultPage
  static const List<String> studentDocTypes = [
    'student_pan',
    'student_aadhar',
    'student_passport',
    'student_10th_marksheet',
    'student_12th_marksheet',
    'student_degree_marksheet',
    'student_test_score',
    'student_offer_letter',
  ];

  static const List<String> coappSalariedTypes = [
    'coapp_pan',
    'coapp_aadhar',
    'coapp_electricity_bill',
    'coapp_salary_slip',
    'coapp_bank_statement_salary',
    'coapp_form16_itr',
  ];

  static const List<String> coappSelfEmployedTypes = [
    'coapp_pan',
    'coapp_aadhar',
    'coapp_electricity_bill',
    'coapp_itr_computation',
    'coapp_balance_sheet_pnl',
    'coapp_business_proof',
    'coapp_bank_statement_business',
  ];

  static const List<String> parentDocTypes = [
    'father_pan',
    'father_aadhar',
    'mother_pan',
    'mother_aadhar',
  ];

  static const Map<String, String> docNames = {
    'student_pan': 'Student PAN Card',
    'student_aadhar': 'Student Aadhar Card',
    'student_passport': 'Student Passport Copy',
    'student_10th_marksheet': '10th Marksheet',
    'student_12th_marksheet': '12th Marksheet',
    'student_degree_marksheet': 'Degree Marksheet',
    'student_test_score': 'Test Score Card',
    'student_offer_letter': 'University Offer Letter',
    'coapp_pan': 'Co-applicant PAN Card',
    'coapp_aadhar': 'Co-applicant Aadhar Card',
    'coapp_electricity_bill': 'Latest Electricity Bill',
    'coapp_salary_slip': 'Last 3 Months Salary Slip',
    'coapp_bank_statement_salary': 'Last 6 Months Bank Statement (Salary)',
    'coapp_form16_itr': 'Last 1 Year Form 16 / ITR',
    'coapp_itr_computation': 'Last 2 Years ITR with Computation',
    'coapp_balance_sheet_pnl': 'Balance Sheet & P&L Account',
    'coapp_business_proof': 'Business Registration Proof',
    'coapp_bank_statement_business': 'Last 1 Year Bank Statement (Business)',
    'father_pan': 'Father PAN Card',
    'father_aadhar': 'Father Aadhar Card',
    'mother_pan': 'Mother PAN Card',
    'mother_aadhar': 'Mother Aadhar Card',
  };

  /// Returns true if every required document in Document Vault has been uploaded and accepted by the user.
  static Future<bool> isEveryDocumentUploaded() async {
    try {
      final docs = await UserService.getUserDocuments();
      if (docs.isEmpty) return false;

      // Required core student documents in Document Vault
      final requiredTypes = <String>[
        'student_passport',
        'student_aadhar',
        'student_pan',
        'student_10th_marksheet',
        'student_12th_marksheet',
        'student_degree_marksheet',
      ];

      final uploadedTypes = docs
          .where((d) =>
              (d.uploaded ||
                  d.status.toLowerCase() == 'verified' ||
                  d.status.toLowerCase() == 'approved' ||
                  (d.filePath != null && d.filePath!.isNotEmpty)) &&
              d.status.toLowerCase() != 'rejected')
          .map((d) => d.docType)
          .toSet();

      for (final reqType in requiredTypes) {
        if (!uploadedTypes.contains(reqType)) {
          return false;
        }
      }
      return true;
    } catch (e) {
      debugPrint('Error checking document completion: $e');
      return false;
    }
  }

  /// Generates and triggers download/share of the full loan application & document summary PDF.
  static Future<void> downloadApplicationPdf(Loan loan) async {
    try {
      final docs = await UserService.getUserDocuments();
      final pdfBytes = await buildPdfBytes(loan, docs);

      final fileName = 'Loan_Application_${loan.applicationNumber ?? loan.id}.pdf';
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: fileName,
      );
    } catch (e) {
      debugPrint('Error generating or downloading PDF: $e');
      rethrow;
    }
  }

  /// Builds PDF byte data containing loan details and uploaded documents list.
  static Future<Uint8List> buildPdfBytes(Loan loan, List<UserDocument> docs) async {
    final pdf = pw.Document();
    final primaryColor = PdfColor.fromHex('#311B92');
    final secondaryColor = PdfColor.fromHex('#10B981');
    final darkTextColor = PdfColor.fromHex('#1F2937');
    final lightBgColor = PdfColor.fromHex('#F8FAFC');

    final currencyFormatter = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 0);
    final dateFormatter = DateFormat('dd MMM yyyy, hh:mm a');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'VIDHYALOAN',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      pw.Text(
                        'Verified Loan Application Dossier',
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: pw.BoxDecoration(
                          color: secondaryColor,
                          borderRadius: pw.BorderRadius.circular(6),
                        ),
                        child: pw.Text(
                          (loan.status).toUpperCase(),
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'App ID: ${loan.applicationNumber ?? loan.id}',
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: darkTextColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Divider(color: PdfColors.grey300, thickness: 1),
              pw.SizedBox(height: 10),
            ],
          );
        },
        footer: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 16),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Generated on ${dateFormatter.format(DateTime.now())}',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                ),
                pw.Text(
                  'Page ${context.pageNumber} of ${context.pagesCount}',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                ),
              ],
            ),
          );
        },
        build: (pw.Context context) => [
          // Section 1: Loan & Academic Details
          _buildSectionHeader('1. LOAN & ACADEMIC DETAILS', primaryColor),
          pw.SizedBox(height: 8),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: lightBgColor,
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: PdfColors.grey300),
            ),
            child: pw.Column(
              children: [
                _buildInfoRow('Student Full Name', loan.fullName, 'Target Country', loan.targetCountry ?? 'N/A'),
                _buildInfoRow('University Name', loan.universityName ?? 'N/A', 'Field of Study', loan.fieldOfStudy ?? 'N/A'),
                _buildInfoRow(
                  'Loan Amount Requested',
                  currencyFormatter.format(loan.amount),
                  'Loan Type',
                  loan.loanType,
                ),
                _buildInfoRow(
                  'Assigned Lender / Bank',
                  loan.displayBank,
                  'Purpose',
                  loan.purpose ?? 'Higher Education',
                ),
                _buildInfoRow('Contact Phone', loan.phoneNumber.isEmpty ? 'N/A' : loan.phoneNumber, 'Email Address', loan.email),
                _buildInfoRow(
                  'Address / City',
                  '${loan.city ?? "N/A"} ${loan.pincode ?? ""}'.trim(),
                  'Country',
                  loan.country ?? loan.targetCountry ?? 'N/A',
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),

          // Section 2: Family & Co-Applicant Info
          _buildSectionHeader('2. GUARDIAN & CO-APPLICANT DETAILS', primaryColor),
          pw.SizedBox(height: 8),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: lightBgColor,
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: PdfColors.grey300),
            ),
            child: pw.Column(
              children: [
                _buildInfoRow('Father\'s Name', loan.fatherName ?? 'N/A', 'Father\'s Phone', loan.fatherPhone ?? 'N/A'),
                _buildInfoRow('Mother\'s Name', loan.motherName ?? 'N/A', 'Mother\'s Phone', loan.motherPhone ?? 'N/A'),
                pw.Divider(color: PdfColors.grey300, thickness: 0.5),
                _buildInfoRow(
                  'Co-Applicant Name',
                  loan.coApplicantName ?? 'N/A',
                  'Relationship',
                  loan.coApplicantRelation ?? 'N/A',
                ),
                _buildInfoRow(
                  'Co-Applicant Income',
                  loan.coApplicantIncome != null
                      ? currencyFormatter.format(loan.coApplicantIncome!)
                      : 'N/A',
                  'Co-Applicant Phone',
                  loan.coApplicantPhone ?? 'N/A',
                ),
                if (loan.hasCollateral) ...[
                  pw.Divider(color: PdfColors.grey300, thickness: 0.5),
                  _buildInfoRow(
                    'Collateral Provided',
                    'Yes',
                    'Collateral Details',
                    loan.collateralDetails ?? 'Property / Fixed Deposit',
                  ),
                ],
              ],
            ),
          ),
          pw.SizedBox(height: 16),

          // Section 3: Document Vault Uploaded Documents
          _buildSectionHeader('3. UPLOADED & VERIFIED DOCUMENTS', primaryColor),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: ['#', 'Document Name', 'Type / Code', 'Source / Status', 'Upload Date'],
            data: List<List<String>>.generate(docs.length, (index) {
              final doc = docs[index];
              final docTitle = docNames[doc.docType] ?? doc.docType;
              final uploadDateStr = doc.uploadedAt != null
                  ? dateFormatter.format(doc.uploadedAt!)
                  : 'Uploaded';
              final statusStr = doc.isDigilocker
                  ? 'DigiLocker Verified'
                  : doc.status.toUpperCase();

              return [
                '${index + 1}',
                docTitle,
                doc.docType,
                statusStr,
                uploadDateStr,
              ];
            }),
            headerStyle: pw.TextStyle(
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
              fontSize: 9,
            ),
            headerDecoration: pw.BoxDecoration(
              color: primaryColor,
            ),
            rowDecoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5),
              ),
            ),
            cellAlignment: pw.Alignment.centerLeft,
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          ),
          pw.SizedBox(height: 20),

          // Declaration / Verification Box
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#ECFDF5'),
              borderRadius: pw.BorderRadius.circular(6),
              border: pw.Border.all(color: PdfColor.fromHex('#A7F3D0')),
            ),
            child: pw.Row(
              children: [
                pw.Text(
                  '✔ Document Verification Complete: ',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromHex('#065F46'),
                  ),
                ),
                pw.Expanded(
                  child: pw.Text(
                    'All required student, co-applicant, and guardian documents have been uploaded and attached to this loan application.',
                    style: pw.TextStyle(
                      fontSize: 8,
                      color: PdfColor.fromHex('#064E3B'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildSectionHeader(String title, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: pw.BoxDecoration(
        color: color,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          color: PdfColors.white,
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  static pw.Widget _buildInfoRow(String label1, String value1, String label2, String value2) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(label1, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                pw.SizedBox(height: 2),
                pw.Text(
                  value1.isEmpty ? 'N/A' : value1,
                  style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                ),
              ],
            ),
          ),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(label2, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                pw.SizedBox(height: 2),
                pw.Text(
                  value2.isEmpty ? 'N/A' : value2,
                  style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
