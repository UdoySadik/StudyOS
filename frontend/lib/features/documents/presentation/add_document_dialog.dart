import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../application/documents_provider.dart';

class AddDocumentDialog extends ConsumerStatefulWidget {
  const AddDocumentDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => const AddDocumentDialog(),
    );
  }

  @override
  ConsumerState<AddDocumentDialog> createState() => _AddDocumentDialogState();
}

class _AddDocumentDialogState extends ConsumerState<AddDocumentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _filePathController = TextEditingController();
  String _selectedDocType = 'textbook';
  bool _isSubmitting = false;

  final List<Map<String, dynamic>> _typeOptions = const [
    {'type': 'textbook', 'label': 'Textbook', 'icon': Icons.menu_book_rounded, 'color': Color(0xFF6366F1)},
    {'type': 'paper', 'label': 'Paper / PDF', 'icon': Icons.article_rounded, 'color': Color(0xFF06B6D4)},
    {'type': 'docs', 'label': 'Documentation', 'icon': Icons.description_rounded, 'color': Color(0xFF10B981)},
    {'type': 'notes', 'label': 'Study Notes', 'icon': Icons.edit_note_rounded, 'color': Color(0xFFF59E0B)},
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _filePathController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      await ref.read(documentsNotifierProvider.notifier).addDocument(
        title: _titleController.text.trim(),
        docType: _selectedDocType,
        content: _contentController.text.trim(),
        filePath: _filePathController.text.trim().isEmpty ? null : _filePathController.text.trim(),
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.success,
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Document indexed and vectorized into RAG chunks!'),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text('Failed to index document: $e'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.darkSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.darkBorder),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.library_books_rounded, color: AppColors.primaryLight, size: 22),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Index Study Document for RAG',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDarkPrimary,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Splits text into search chunks with TF-IDF vectors for citations and offline Q&A',
                            style: TextStyle(fontSize: 12, color: AppColors.textDarkSecondary),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppColors.textDarkSecondary),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const Divider(color: AppColors.darkBorder, height: 28),

                // Body Fields
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        const Text(
                          'DOCUMENT TITLE',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.1,
                            color: AppColors.textDarkSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          key: const Key('add_document_title_field'),
                          controller: _titleController,
                          style: const TextStyle(color: AppColors.textDarkPrimary, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'e.g. Designing Data-Intensive Applications: Chapter 5',
                            hintStyle: const TextStyle(color: AppColors.textDarkMuted, fontSize: 13),
                            filled: true,
                            fillColor: AppColors.darkCard,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: AppColors.darkBorder),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: AppColors.darkBorder),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: AppColors.primary),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'Please enter document title';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Doc Type Selector
                        const Text(
                          'DOCUMENT TYPE',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.1,
                            color: AppColors.textDarkSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _typeOptions.map((opt) {
                            final isSelected = _selectedDocType == opt['type'];
                            final optColor = opt['color'] as Color;
                            return InkWell(
                              onTap: () => setState(() => _selectedDocType = opt['type'] as String),
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected ? optColor.withValues(alpha: 0.2) : AppColors.darkCard,
                                  border: Border.all(
                                    color: isSelected ? optColor : AppColors.darkBorder,
                                    width: isSelected ? 1.5 : 1.0,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(opt['icon'] as IconData, size: 16, color: isSelected ? optColor : AppColors.textDarkSecondary),
                                    const SizedBox(width: 8),
                                    Text(
                                      opt['label'] as String,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                        color: isSelected ? Colors.white : AppColors.textDarkSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),

                        // File Path (Optional)
                        const Text(
                          'FILE PATH (OPTIONAL)',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.1,
                            color: AppColors.textDarkSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          key: const Key('add_document_file_path_field'),
                          controller: _filePathController,
                          style: const TextStyle(color: AppColors.textDarkPrimary, fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'e.g. /books/ddia.pdf or D:/papers/raft.pdf',
                            hintStyle: const TextStyle(color: AppColors.textDarkMuted, fontSize: 13),
                            filled: true,
                            fillColor: AppColors.darkCard,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: AppColors.darkBorder),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: AppColors.darkBorder),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Content Field
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'DOCUMENT CONTENT',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.1,
                                color: AppColors.textDarkSecondary,
                              ),
                            ),
                            Flexible(
                              child: Text(
                                'Tip: insert "--- Page 1 ---" for pagination',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 11, color: AppColors.accent),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          key: const Key('add_document_content_field'),
                          controller: _contentController,
                          maxLines: 10,
                          minLines: 6,
                          style: const TextStyle(
                            color: AppColors.textDarkPrimary,
                            fontSize: 13,
                            fontFamily: 'monospace',
                            height: 1.4,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Paste paper excerpt, textbook chapter, or documentation markdown here...\n\n--- Page 1 ---\nIntroduction to system design...\n\n--- Page 2 ---\nConsensus protocols...',
                            hintStyle: const TextStyle(color: AppColors.textDarkMuted, fontSize: 12),
                            filled: true,
                            fillColor: AppColors.darkCard,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: AppColors.darkBorder),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: AppColors.darkBorder),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: AppColors.primary),
                            ),
                            contentPadding: const EdgeInsets.all(14),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().length < 20) {
                              return 'Please provide at least 20 characters of document content.';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const Divider(color: AppColors.darkBorder, height: 24),

                // Action Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textDarkSecondary,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      key: const Key('add_document_submit_btn'),
                      onPressed: _isSubmitting ? null : _handleSubmit,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.auto_awesome_rounded, size: 16),
                      label: Text(_isSubmitting ? 'Processing & Vectorizing...' : 'Index Document'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
