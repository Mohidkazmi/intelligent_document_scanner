import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:doc_scanner/core/theme.dart';
import 'package:doc_scanner/services/document_service.dart';
import 'package:doc_scanner/services/ocr_service.dart';
import 'package:doc_scanner/ui/screens/ocr_result_screen.dart';

class DocumentDetailScreen extends StatefulWidget {
  final Map<String, dynamic> document;
  final String imageUrl;

  const DocumentDetailScreen({
    super.key,
    required this.document,
    required this.imageUrl,
  });

  @override
  State<DocumentDetailScreen> createState() => _DocumentDetailScreenState();
}

class _DocumentDetailScreenState extends State<DocumentDetailScreen> {
  late Map<String, dynamic> _document;
  bool _ocrBusy = false;

  @override
  void initState() {
    super.initState();
    _document = Map<String, dynamic>.from(widget.document);
  }

  static int _documentId(Map<String, dynamic> doc) {
    final id = doc['id'];
    if (id is int) return id;
    return int.parse(id.toString());
  }

  Future<void> _deleteDocument() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text("Delete Document",
            style: TextStyle(color: Colors.white)),
        content: const Text(
          "Are you sure you want to delete this document?",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await DocumentService().deleteDocument(_documentId(_document));
        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Document deleted")),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Error: $e"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _openExistingOcrText() async {
    final existing = _document['ocr_text'] as String?;
    if (existing == null || existing.trim().isEmpty) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OcrResultScreen(
          text: existing,
          showEngineMeta: false,
        ),
      ),
    );
  }

  Future<void> _runOcr() async {
    if (_ocrBusy) return;
    setState(() => _ocrBusy = true);
    try {
      final result = await OcrService().extractText(_documentId(_document));
      final text = result['text'] as String? ?? '';

      if (!mounted) return;
      setState(() {
        _document['ocr_text'] = text;
        _ocrBusy = false;
      });

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OcrResultScreen(
            text: text,
            engine: result['engine'] as String? ?? 'tesseract',
            lang: result['lang'] as String? ?? 'eng',
            blocks: result['blocks'] as List<dynamic>?,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('OCR failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _ocrBusy = false);
      }
    }
  }

  Future<void> _extractOrViewText() async {
    final existing = (_document['ocr_text'] as String?)?.trim() ?? '';
    if (existing.isNotEmpty) {
      await _openExistingOcrText();
    } else {
      await _runOcr();
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasCachedText =
        ((_document['ocr_text'] as String?)?.trim().isNotEmpty ?? false);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(_document['filename']?.toString() ?? 'Document'),
        actions: [
          if (_ocrBusy)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: Icon(
                hasCachedText ? Icons.subject : Icons.text_fields,
                color: Colors.white70,
              ),
              tooltip: hasCachedText ? 'View extracted text' : 'Extract text',
              onPressed: _extractOrViewText,
            ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: _deleteDocument,
          ),
        ],
      ),
      body: Center(
        child: PhotoView(
          imageProvider: NetworkImage(widget.imageUrl),
          loadingBuilder: (context, event) =>
              const Center(child: CircularProgressIndicator()),
          errorBuilder: (context, error, stackTrace) => const Center(
            child:
                Icon(Icons.broken_image, color: Colors.white24, size: 100),
          ),
          backgroundDecoration: const BoxDecoration(color: Colors.black),
        ),
      ),
    );
  }
}
