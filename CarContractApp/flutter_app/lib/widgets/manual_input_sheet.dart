import 'dart:ui';
import 'package:flutter/material.dart';

/// Bottom sheet UI for graceful degradation — allows users to manually
/// enter missing critical fields when OCR confidence is low or
/// the Gemini API times out.
class ManualInputSheet extends StatefulWidget {
  /// Pre-filled values from partial OCR extraction
  final Map<String, dynamic>? partialData;

  /// Called with the manually entered data
  final void Function(Map<String, dynamic> data) onSubmit;

  const ManualInputSheet({super.key, this.partialData, required this.onSubmit});

  @override
  State<ManualInputSheet> createState() => _ManualInputSheetState();

  /// Show as a modal bottom sheet
  static Future<void> show(
    BuildContext context, {
    Map<String, dynamic>? partialData,
    required void Function(Map<String, dynamic>) onSubmit,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) =>
          ManualInputSheet(partialData: partialData, onSubmit: onSubmit),
    );
  }
}

class _ManualInputSheetState extends State<ManualInputSheet> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _aprController;
  late TextEditingController _monthlyPaymentController;
  late TextEditingController _termMonthsController;
  late TextEditingController _downPaymentController;
  late TextEditingController _mileageLimitController;
  late TextEditingController _buyoutPriceController;

  @override
  void initState() {
    super.initState();
    final d = widget.partialData ?? {};
    _aprController = TextEditingController(text: d['apr']?.toString() ?? '');
    _monthlyPaymentController = TextEditingController(
      text: d['monthly_payment']?.toString() ?? '',
    );
    _termMonthsController = TextEditingController(
      text: d['term_months']?.toString() ?? '',
    );
    _downPaymentController = TextEditingController(
      text: d['down_payment']?.toString() ?? '',
    );
    _mileageLimitController = TextEditingController(
      text: d['mileage_limit']?.toString() ?? '',
    );
    _buyoutPriceController = TextEditingController(
      text: d['buyout_price']?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _aprController.dispose();
    _monthlyPaymentController.dispose();
    _termMonthsController.dispose();
    _downPaymentController.dispose();
    _mileageLimitController.dispose();
    _buyoutPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E).withOpacity(0.92),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                border: Border.all(
                  color: Colors.white.withOpacity(0.08),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFFFFB74D,
                                ).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.edit_note_rounded,
                                color: Color(0xFFFFB74D),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Manual Input',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Enter the key contract terms below',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.5),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Info banner
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4FC3F7).withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF4FC3F7).withOpacity(0.15),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                color: const Color(0xFF4FC3F7).withOpacity(0.7),
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Our AI couldn\'t confidently extract all terms. '
                                  'Please verify and fill in the missing fields.',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.6),
                                    fontSize: 12,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Form
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            _buildField(
                              'APR (%)',
                              _aprController,
                              Icons.percent_rounded,
                              keyboardType: TextInputType.number,
                            ),
                            _buildField(
                              'Monthly Payment (\$)',
                              _monthlyPaymentController,
                              Icons.payments_rounded,
                              keyboardType: TextInputType.number,
                            ),
                            _buildField(
                              'Term (months)',
                              _termMonthsController,
                              Icons.calendar_month_rounded,
                              keyboardType: TextInputType.number,
                            ),
                            _buildField(
                              'Down Payment (\$)',
                              _downPaymentController,
                              Icons.savings_rounded,
                              keyboardType: TextInputType.number,
                            ),
                            _buildField(
                              'Annual Mileage Limit',
                              _mileageLimitController,
                              Icons.speed_rounded,
                              keyboardType: TextInputType.number,
                            ),
                            _buildField(
                              'Buyout / Purchase Price (\$)',
                              _buyoutPriceController,
                              Icons.shopping_cart_rounded,
                              keyboardType: TextInputType.number,
                            ),

                            const SizedBox(height: 24),

                            // Submit button
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _handleSubmit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF7C4DFF),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: const Text(
                                  'Submit & Analyze',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller,
    IconData icon, {
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.white.withOpacity(0.4),
            fontSize: 14,
          ),
          prefixIcon: Icon(
            icon,
            color: Colors.white.withOpacity(0.3),
            size: 20,
          ),
          filled: true,
          fillColor: Colors.white.withOpacity(0.05),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF7C4DFF), width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  void _handleSubmit() {
    final data = <String, dynamic>{};

    double? tryDouble(String s) {
      if (s.isEmpty) return null;
      return double.tryParse(s.replaceAll(RegExp(r'[^\d.]'), ''));
    }

    int? tryInt(String s) {
      if (s.isEmpty) return null;
      return int.tryParse(s.replaceAll(RegExp(r'[^\d]'), ''));
    }

    data['apr'] = tryDouble(_aprController.text);
    data['monthly_payment'] = tryDouble(_monthlyPaymentController.text);
    data['term_months'] = tryInt(_termMonthsController.text);
    data['down_payment'] = tryDouble(_downPaymentController.text);
    data['mileage_limit'] = tryInt(_mileageLimitController.text);
    data['buyout_price'] = tryDouble(_buyoutPriceController.text);

    widget.onSubmit(data);
    Navigator.of(context).pop();
  }
}
