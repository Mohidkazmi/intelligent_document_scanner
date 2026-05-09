import 'dart:io';
import 'package:flutter/material.dart';
import 'package:doc_scanner/core/theme.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:doc_scanner/services/document_service.dart';
import 'package:doc_scanner/services/scanner_service.dart';
import 'package:doc_scanner/core/constants.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class ImagePreviewScreen extends StatefulWidget {
  final String imagePath;
  const ImagePreviewScreen({super.key, required this.imagePath});

  @override
  State<ImagePreviewScreen> createState() => _ImagePreviewScreenState();
}

class _ImagePreviewScreenState extends State<ImagePreviewScreen> {
  String? _processedImagePath;
  bool _isProcessing = false;
  String _selectedFilter = 'original';
  
  final _documentService = DocumentService();
  final _scannerService = ScannerService();
  int? _documentId;
  String? _remoteUrl;
  bool _isRemote = false;

  @override
  void initState() {
    super.initState();
    _processedImagePath = widget.imagePath;
  }

  void _applyFilter(String filter) async {
    if (filter == 'original') {
      setState(() {
        _selectedFilter = filter;
        _isRemote = false;
      });
      return;
    }

    setState(() {
      _selectedFilter = filter;
      _isProcessing = true;
    });

    try {
      // 1. Upload if not already uploaded
      if (_documentId == null) {
        final doc = await _documentService.uploadDocument(File(_processedImagePath!));
        _documentId = doc['id'];
      }

      // 2. Enhance
      final result = await _scannerService.enhanceImage(_documentId!, filter);
      
      setState(() {
        _remoteUrl = result['url'];
        _isRemote = true;
        _isProcessing = false;
      });
    } catch (e) {
      debugPrint("Enhancement error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Processing failed: $e"), backgroundColor: Colors.red),
        );
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _flattenImage() async {
    setState(() => _isProcessing = true);
    try {
      // 1. Upload if needed
      if (_documentId == null) {
        final doc = await _documentService.uploadDocument(File(_processedImagePath!));
        _documentId = doc['id'];
      }

      // 2. Detect edges
      final edgeResult = await _scannerService.detectEdges(_documentId!);
      final corners = edgeResult['corners'];

      // 3. Correct perspective
      final perspectiveResult = await _scannerService.correctPerspective(_documentId!, corners);
      
      setState(() {
        _remoteUrl = perspectiveResult['url'];
        _isRemote = true;
        _isProcessing = false;
        _selectedFilter = 'original'; // Reset filter to original of the new flat image
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Image flattened successfully"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      debugPrint("Flatten error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Flattening failed: $e"), backgroundColor: Colors.red),
        );
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _cropImage() async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: _processedImagePath!,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Document',
          toolbarColor: AppTheme.surfaceColor,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
          activeControlsWidgetColor: AppTheme.primaryColor,
        ),
        IOSUiSettings(
          title: 'Crop Document',
        ),
      ],
    );

    if (croppedFile != null) {
      setState(() {
        _processedImagePath = croppedFile.path;
        _documentId = null; // Reset ID because file changed
        _isRemote = false;
        _selectedFilter = 'original';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text("Preview"),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_fix_normal, color: Colors.white),
            tooltip: 'AI Flatten',
            onPressed: _flattenImage,
          ),
          IconButton(
            icon: const Icon(Icons.crop_rotate, color: Colors.white),
            onPressed: _cropImage,
          ),
          IconButton(
            icon: const Icon(Icons.check, color: AppTheme.primaryColor),
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Document saved successfully"), backgroundColor: Colors.green),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Image Display
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 10),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    _isRemote
                        ? Image.network(
                            '${AppConstants.baseUrl.replaceAll("/api/v1", "")}$_remoteUrl',
                            fit: BoxFit.contain,
                            width: double.infinity,
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return const Center(child: CircularProgressIndicator());
                            },
                            errorBuilder: (context, error, stackTrace) {
                              debugPrint("Network Image Error: $error");
                              return Image.file(
                                File(_processedImagePath!),
                                fit: BoxFit.contain,
                                width: double.infinity,
                              );
                            },
                          )
                        : Image.file(
                            File(_processedImagePath!),
                            fit: BoxFit.contain,
                            width: double.infinity,
                          ),
                    if (_isProcessing)
                      Container(
                        color: Colors.black45,
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // 2. Filter Bar
          Container(
            height: 120,
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildFilterItem('original', 'Original', Icons.image_outlined),
                _buildFilterItem('magic', 'Magic', Icons.auto_fix_high),
                _buildFilterItem('bw', 'B&W', Icons.contrast),
                _buildFilterItem('grayscale', 'Grayscale', Icons.gradient),
                _buildFilterItem('receipt', 'Receipt', Icons.receipt_long),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterItem(String id, String label, IconData icon) {
    final isSelected = _selectedFilter == id;
    return GestureDetector(
      onTap: () => _applyFilter(id),
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? Colors.white24 : Colors.transparent),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.white70),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.white : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
