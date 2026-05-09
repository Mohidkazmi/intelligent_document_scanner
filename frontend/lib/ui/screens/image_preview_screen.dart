import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:doc_scanner/core/theme.dart';
import 'package:doc_scanner/providers/camera_provider.dart';

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

  @override
  void initState() {
    super.initState();
    _processedImagePath = widget.imagePath;
  }

  void _applyFilter(String filter) async {
    // TODO: Connect to backend enhancement API
    setState(() {
      _selectedFilter = filter;
      _isProcessing = true;
    });
    
    // Simulate processing for now
    await Future.delayed(const Duration(seconds: 1));
    
    setState(() {
      _isProcessing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text("Preview"),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: AppTheme.primaryColor),
            onPressed: () {
              // TODO: Save document logic
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
                  BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    Image.file(
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
