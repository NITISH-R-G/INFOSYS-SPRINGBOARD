import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class OfferBuilderScreen extends StatefulWidget {
  const OfferBuilderScreen({super.key});

  @override
  State<OfferBuilderScreen> createState() => _OfferBuilderScreenState();
}

class _OfferBuilderScreenState extends State<OfferBuilderScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form Controllers
  final _customerNameCtrl = TextEditingController();
  final _vehicleCtrl = TextEditingController(); // Make/Model/Year
  final _priceCtrl = TextEditingController();
  final _termCtrl = TextEditingController(); // Months
  final _aprCtrl = TextEditingController();

  bool _isSubmitting = false;

  Future<void> _submitOffer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    // Simulate creation via API
    try {
      // In real app, we would post to ApiService.createContract(...)
      // For prototype, we'll just simulate a delay and go back
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Offer Created & Sent to Client')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Offer'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'CUSTOMER DETAILS',
                style: TextStyle(
                  color: AppTheme.accentBlue,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              _buildTextField(_customerNameCtrl, 'Customer Name', Icons.person),
              const SizedBox(height: 24),

              const Text(
                'VEHICLE INFORMATION',
                style: TextStyle(
                  color: AppTheme.accentBlue,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              _buildTextField(
                _vehicleCtrl,
                'Vehicle (Year Make Model)',
                Icons.directions_car,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                _priceCtrl,
                'Sale Price (₹)',
                Icons.attach_money,
                isNumber: true,
              ),
              const SizedBox(height: 24),

              const Text(
                'FINANCE TERMS',
                style: TextStyle(
                  color: AppTheme.accentBlue,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      _termCtrl,
                      'Term (Months)',
                      Icons.calendar_today,
                      isNumber: true,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      _aprCtrl,
                      'APR (%)',
                      Icons.percent,
                      isNumber: true,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitOffer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'SEND OFFER',
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
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isNumber = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: AppTheme.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppTheme.textSecondary),
        prefixIcon: Icon(icon, color: AppTheme.textMuted),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.accentBlue),
        ),
        filled: true,
        fillColor: AppTheme.glassBg,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $label';
        }
        return null;
      },
    );
  }
}
