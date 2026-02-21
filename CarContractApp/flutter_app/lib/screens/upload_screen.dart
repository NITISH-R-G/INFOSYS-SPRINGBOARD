import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../widgets/glass_card.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  Uint8List? _fileBytes;
  String? _fileName;
  bool _isUploading = false;
  bool _isAnalyzing = false;
  String? _error;
  double _progress = 0;

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
        withData: true, // Required for web - loads file bytes
      );

      if (result != null && result.files.single.bytes != null) {
        setState(() {
          _fileBytes = result.files.single.bytes;
          _fileName = result.files.single.name;
          _error = null;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to pick file: $e';
      });
    }
  }

  Future<void> _uploadAndAnalyze() async {
    if (_fileBytes == null || _fileName == null) return;

    setState(() {
      _isUploading = true;
      _error = null;
      _progress = 0.3;
    });

    try {
      // Upload using bytes
      final uploadResult = await ApiService.uploadContractBytes(
        _fileBytes!,
        _fileName!,
      );
      final contractId = uploadResult['id'];

      setState(() {
        _isUploading = false;
        _isAnalyzing = true;
        _progress = 0.6;
      });

      // Analyze
      await ApiService.analyzeContract(contractId);

      setState(() {
        _progress = 1.0;
      });

      // Navigate to detail
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/contract/$contractId');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isUploading = false;
        _isAnalyzing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Contract'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drop zone
              Expanded(
                child: GestureDetector(
                  onTap: _pickFile,
                  child: GlassCard(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _fileBytes != null
                              ? Icons.check_circle_outline
                              : Icons.cloud_upload_outlined,
                          size: 64,
                          color: _fileBytes != null
                              ? AppTheme.accentGreen
                              : AppTheme.textMuted,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _fileName ?? 'Tap to select a contract',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: _fileBytes != null
                                ? AppTheme.textPrimary
                                : AppTheme.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'PDF, PNG, JPG (Max 10MB)',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Progress indicator
              if (_isUploading || _isAnalyzing)
                Column(
                  children: [
                    LinearProgressIndicator(
                      value: _progress,
                      backgroundColor: AppTheme.glassBg,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppTheme.accentGreen,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _isAnalyzing ? 'Analyzing with AI...' : 'Uploading...',
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),

              // Error message
              if (_error != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.accentRed.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.accentRed.withOpacity(0.5),
                    ),
                  ),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: AppTheme.accentRed),
                  ),
                ),

              // Action button
              ElevatedButton(
                onPressed: _fileBytes != null && !_isUploading && !_isAnalyzing
                    ? _uploadAndAnalyze
                    : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  disabledBackgroundColor: AppTheme.glassBg,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isUploading || _isAnalyzing
                          ? Icons.hourglass_empty
                          : Icons.auto_awesome,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _isAnalyzing
                          ? 'Analyzing...'
                          : _isUploading
                          ? 'Uploading...'
                          : 'Analyze with AI',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
