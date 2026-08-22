import 'package:flutter/material.dart';

import '../models/document_info.dart';

class DocumentHeader extends StatelessWidget {
  const DocumentHeader({
    super.key,
    required this.documentInfo,
    required this.isUploading,
    required this.statusText,
    required this.onUploadPressed,
    required this.onClearPressed,
  });

  final DocumentInfo? documentInfo;
  final bool isUploading;
  final String? statusText;
  final VoidCallback onUploadPressed;
  final VoidCallback onClearPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.secondary,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.picture_as_pdf_rounded,
                color: Colors.black,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                documentInfo == null
                    ? 'No PDF loaded yet'
                    : '${documentInfo!.filename} • ${documentInfo!.pages} pages • ${documentInfo!.chunks} chunks',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                ),
              ),
            ),
            const SizedBox(width: 12),
            TextButton(
              onPressed: isUploading ? null : onClearPressed,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white70,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                ),
              ),
              child: const Text('Clear'),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: isUploading ? null : onUploadPressed,
              icon: isUploading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.upload_file_rounded),
              label: const Text('Upload PDF'),
            ),
          ],
        ),
      ),
    );
  }
}
