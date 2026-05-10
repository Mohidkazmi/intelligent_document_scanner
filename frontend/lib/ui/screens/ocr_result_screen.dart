import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:doc_scanner/core/theme.dart';

/// Shows OCR output with copy support. Optional [blocks] reserved for future UI (e.g. highlights).
class OcrResultScreen extends StatelessWidget {
  final String title;
  final String text;
  final String engine;
  final String lang;
  final List<dynamic>? blocks;
  final bool showEngineMeta;

  const OcrResultScreen({
    super.key,
    this.title = 'Extracted text',
    required this.text,
    this.engine = 'tesseract',
    this.lang = 'eng',
    this.blocks,
    this.showEngineMeta = true,
  });

  @override
  Widget build(BuildContext context) {
    final trimmed = text.trim();
    final showChips =
        showEngineMeta && (engine.isNotEmpty || lang.isNotEmpty);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'Copy all',
            onPressed: trimmed.isEmpty
                ? null
                : () {
                    Clipboard.setData(ClipboardData(text: text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copied to clipboard')),
                    );
                  },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showChips)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (engine.isNotEmpty)
                    Chip(
                      label: Text(engine, style: const TextStyle(fontSize: 12)),
                      backgroundColor: AppTheme.surfaceColor,
                      labelStyle: const TextStyle(color: Colors.white70),
                    ),
                  if (lang.isNotEmpty)
                    Chip(
                      label: Text(lang, style: const TextStyle(fontSize: 12)),
                      backgroundColor: AppTheme.surfaceColor,
                      labelStyle: const TextStyle(color: Colors.white70),
                    ),
                  if (blocks != null)
                    Chip(
                      label: Text(
                        '${blocks!.length} regions',
                        style: const TextStyle(fontSize: 12),
                      ),
                      backgroundColor: AppTheme.surfaceColor,
                      labelStyle: const TextStyle(color: Colors.white70),
                    ),
                ],
              ),
            ),
          Expanded(
            child: trimmed.isEmpty
                ? const Center(
                    child: Text(
                      'No text detected',
                      style: TextStyle(color: Colors.white54),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: SelectableText(
                      text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
