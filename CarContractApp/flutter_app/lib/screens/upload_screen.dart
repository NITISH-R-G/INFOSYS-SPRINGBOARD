import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:async';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/task_status_overlay.dart';
import '../widgets/manual_input_sheet.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  Uint8List? _fileBytes;
  String? _fileName;
  bool _isProcessing = false;
  String? _error;

  // Task status overlay state
  String _taskStage = 'scanning';
  String _taskMessage = 'Preparing...';
  double _taskProgress = 0;
  int? _contractId;

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
        withData: true,
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

  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  Future<void> _uploadAndAnalyze() async {
    if (_fileBytes == null || _fileName == null) return;

    setState(() {
      _isProcessing = true;
      _error = null;
      _taskStage = 'scanning';
      _taskMessage = 'Uploading document...';
      _taskProgress = 5;
    });

    try {
      // Stage 1: Upload
      final uploadResult = await ApiService.uploadContractBytes(
        _fileBytes!,
        _fileName!,
      );
      _contractId = uploadResult['id'];
      final jobId = uploadResult['job_id'];

      if (jobId != null) {
        // Connect to WebSocket for real-time progress
        // Extract host from baseUrl
        final uri = Uri.parse(ApiService.baseUrl);
        final wsUrl =
            '${uri.scheme == 'https' ? 'wss' : 'ws'}://${uri.host}:${uri.port}/ws/tasks/$jobId';
        final channel = WebSocketChannel.connect(Uri.parse(wsUrl));

        channel.stream.listen(
          (message) {
            if (_isDisposed) return;
            try {
              final data = jsonDecode(message as String);

              if (mounted) {
                setState(() {
                  _taskStage = data['status'] ?? _taskStage;
                  _taskProgress = (data['progress'] ?? _taskProgress)
                      .toDouble();
                  if (data['message'] != null) {
                    _taskMessage = data['message'];
                  }

                  if (_taskStage == 'completed' || _taskStage == 'complete') {
                    _taskStage = 'complete';
                    _taskProgress = 100;
                  } else if (_taskStage == 'failed' || _taskStage == 'error') {
                    _taskStage = 'error';
                    if (data['error'] != null) {
                      _taskMessage = data['error'];
                    }
                  }
                });
              }
            } catch (e) {
              // If parsing fails, just ignore and keep current status
              print("WebSocket message parsing error: $e");
            }
          },
          onError: (error) {
            if (mounted) {
              setState(() {
                _taskStage = 'error';
                _taskMessage = 'WebSocket error: $error';
                _taskProgress = 0;
              });
            }
          },
          onDone: () {
            // Connection closed. If it closed without completing, we might want to check the status via HTTP as a fallback.
            if (_taskStage != 'complete' && _taskStage != 'error' && mounted) {
              // In a production app, trigger an HTTP poll here.
            }
          },
        );
      } else {
        // Fallback if no job_id is returned (sync processing)
        setState(() {
          _taskStage = 'analyzing';
          _taskMessage = 'Calculating Fairness Score...';
          _taskProgress = 80;
        });

        await ApiService.analyzeContract(_contractId.toString());

        setState(() {
          _taskStage = 'complete';
          _taskMessage = 'Analysis complete!';
          _taskProgress = 100;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        // Check if this is an OCR/LLM error where manual input could help
        if (e.errorCode == 'OCR_PROCESSING_ERROR' ||
            e.errorCode == 'LLM_ANALYSIS_ERROR' ||
            e.errorCode == 'LOW_OCR_CONFIDENCE') {
          setState(() {
            _taskStage = 'error';
            _taskMessage = e.message;
            _taskProgress = 0;
          });
        } else {
          setState(() {
            _isProcessing = false;
            _error = e.message;
          });
        }
      }
    } on AuthExpiredException catch (e) {
      if (mounted) {
        setState(() {
          _taskStage = 'error';
          _taskMessage = e.message; // 'Session expired. Please log in again.'
          _taskProgress = 0;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _taskStage = 'error';
          _taskMessage =
              'Processing failed. Please try again or input manually.';
          _taskProgress = 0;
        });
      }
    }
  }

  void _handleViewResults() {
    setState(() {
      _isProcessing = false;
    });
    if (_contractId != null && mounted) {
      Navigator.pushReplacementNamed(context, '/contract/$_contractId');
    }
  }

  void _handleRetry() {
    setState(() {
      _isProcessing = false;
      _error = null;
    });
    _uploadAndAnalyze();
  }

  void _handleManualInput() {
    setState(() {
      _isProcessing = false;
    });
    ManualInputSheet.show(
      context,
      onSubmit: (data) {
        // TODO: Submit manual data to backend
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Manual data submitted for analysis.'),
            backgroundColor: Color(0xFF7C4DFF),
          ),
        );
      },
    );
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
      body: Stack(
        children: [
          // Main content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Drop zone
                  Expanded(
                    child: GestureDetector(
                      onTap: _isProcessing ? null : _pickFile,
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

                  // Error message (non-overlay errors)
                  if (_error != null && !_isProcessing)
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
                      child: Row(
                        children: [
                          const Icon(
                            Icons.warning_rounded,
                            color: AppTheme.accentRed,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _error!,
                              style: const TextStyle(
                                color: AppTheme.accentRed,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Action button
                  ElevatedButton(
                    onPressed: _fileBytes != null && !_isProcessing
                        ? _uploadAndAnalyze
                        : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      disabledBackgroundColor: AppTheme.glassBg,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.auto_awesome, size: 22),
                        const SizedBox(width: 10),
                        const Text('Analyze with AI'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Glassmorphism overlay (shown during processing)
          if (_isProcessing)
            TaskStatusOverlay(
              stage: _taskStage,
              message: _taskMessage,
              progress: _taskProgress,
              onComplete: _handleViewResults,
              onRetry: _handleRetry,
              onManualInput: _handleManualInput,
            ),
        ],
      ),
    );
  }
}
