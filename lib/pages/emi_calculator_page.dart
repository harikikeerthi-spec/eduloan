import 'package:flutter/material.dart';
import 'dart:math';
import '../widgets/mesh_background.dart';
import '../widgets/institute_selection_modal.dart';
import '../data/institutes_data.dart';

class EmiCalculatorPage extends StatefulWidget {
  const EmiCalculatorPage({super.key});

  @override
  State<EmiCalculatorPage> createState() => _EmiCalculatorPageState();
}

class _EmiCalculatorPageState extends State<EmiCalculatorPage> {
  final TextEditingController _instituteController = TextEditingController();
  final TextEditingController _courseController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _rateController = TextEditingController(
    text: "10.5",
  );
  final TextEditingController _tenureController = TextEditingController();

  double? _monthlyEmi;
  double? _totalInterest;
  double? _totalPayment;

  @override
  void dispose() {
    _instituteController.dispose();
    _courseController.dispose();
    _amountController.dispose();
    _rateController.dispose();
    _tenureController.dispose();
    super.dispose();
  }

  void _calculateEmi() {
    FocusScope.of(context).unfocus();

    final double amount = double.tryParse(_amountController.text) ?? 0;
    final double rate = double.tryParse(_rateController.text) ?? 0;
    final double years = double.tryParse(_tenureController.text) ?? 0;

    if (amount <= 0 || rate <= 0 || years <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter valid details'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final double monthlyRate = rate / (12 * 100);
    final double months = years * 12;

    final double emi =
        (amount * monthlyRate * pow(1 + monthlyRate, months)) /
        (pow(1 + monthlyRate, months) - 1);

    setState(() {
      _monthlyEmi = emi;
      _totalPayment = emi * months;
      _totalInterest = _totalPayment! - amount;
    });
  }

  Future<void> _showInstituteSelection() async {
    final result = await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const InstituteSelectionModal(),
    );

    if (result != null && result is Map) {
      final Institute institute = result['institute'];
      final String course = result['course'];

      setState(() {
        _instituteController.text = institute.name;
        _courseController.text = course;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MeshBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF1F2937)),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Repayment Calculator',
            style: TextStyle(
              color: Color(0xFF1F2937),
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.help_outline, color: Color(0xFF1F2937)),
              onPressed: () {},
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              // Header Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                decoration: BoxDecoration(
                  color: const Color(
                    0xFF311B92,
                  ).withValues(alpha: 0.05), // Light purple hint
                  border: Border(
                    bottom: BorderSide(
                      color: const Color(0xFF311B92).withValues(alpha: 0.05),
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    RichText(
                      textAlign: TextAlign.center,
                      text: const TextSpan(
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          height: 1.4,
                        ),
                        children: [
                          TextSpan(text: 'Plan Your Repayments Easily\nwith '),
                          TextSpan(
                            text: 'Edu Loan EMI Calculator',
                            style: TextStyle(
                              color: Color(0xFF311B92), // Use brand color
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Calculator Form Card
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF311B92).withValues(alpha: 0.08),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Explore Repayment Plans',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black, // Changed from white
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Institute Input
                    _buildInputField(
                      hint: 'Select Institute',
                      icon: Icons.account_balance_outlined,
                      onTap: _showInstituteSelection,
                      controller: _instituteController,
                    ),
                    const SizedBox(height: 16),

                    // Course Input
                    _buildInputField(
                      hint: 'Select Course',
                      icon: Icons.school_outlined,
                      onTap:
                          _showInstituteSelection, // Re-open selection if clicked
                      controller: _courseController,
                    ),
                    const SizedBox(height: 16),

                    // Loan Amount Input
                    _buildNumberField(
                      label: 'Loan Amount (₹)',
                      hint: 'e.g. 500000',
                      icon: Icons.currency_rupee,
                      controller: _amountController,
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: _buildNumberField(
                            label: 'Interest Rate (%)',
                            hint: '10.5',
                            icon: Icons.percent,
                            controller: _rateController,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildNumberField(
                            label: 'Tenure (Years)',
                            hint: 'e.g. 2',
                            icon: Icons.calendar_today,
                            controller: _tenureController,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Results Display
                    if (_monthlyEmi != null) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF311B92,
                          ).withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(
                              0xFF311B92,
                            ).withValues(alpha: 0.1),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Monthly EMI',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black.withValues(alpha: 0.6),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '₹${_monthlyEmi!.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF311B92),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Total Interest',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.black.withValues(
                                          alpha: 0.6,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '₹${_totalInterest!.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Total Amount',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.black.withValues(
                                          alpha: 0.6,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '₹${_totalPayment!.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],

                    // Action Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _calculateEmi,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF311B92),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Calculate EMI',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 48),

              // Features Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const Text(
                      'Why the Edu Loan EMI Calculator is the perfect choice for you!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black, // Visible on background
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildFeatureCard(
                      icon: Icons.savings_outlined,
                      title: 'Customizable Repayment Plans',
                      description:
                          'Customize repayment options to fit your future budget.',
                      color: const Color(0xFF10B981),
                    ),
                    const SizedBox(height: 16),
                    _buildFeatureCard(
                      icon: Icons.auto_graph_outlined,
                      title: 'Fast and Accurate Results',
                      description:
                          'Get accurate insights to choose the best loan plan.',
                      color: const Color(0xFF311B92).withValues(alpha: 0.1),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumberField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF311B92).withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF311B92).withValues(alpha: 0.05),
            ),
          ),
          child: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black, // Ensure text is black
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: Colors.black.withValues(alpha: 0.4),
                fontSize: 16,
              ),
              border: InputBorder.none,
              suffixIcon: Icon(
                icon,
                color: const Color(0xFF311B92).withValues(alpha: 0.5),
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required String hint,
    required IconData icon,
    required VoidCallback onTap,
    required TextEditingController controller,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF311B92).withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF311B92).withValues(alpha: 0.05),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                controller.text.isEmpty ? hint : controller.text,
                style: TextStyle(
                  color: controller.text.isEmpty
                      ? Colors.black.withValues(alpha: 0.4)
                      : Colors.black,
                  fontSize: 16,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(icon, color: const Color(0xFF311B92).withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF311B92).withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black, // Changed from white
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black.withValues(alpha: 0.6),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
