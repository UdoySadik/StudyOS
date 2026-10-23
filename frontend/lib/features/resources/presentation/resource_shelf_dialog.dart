import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../application/resources_provider.dart';
import '../domain/resource_model.dart';

class ResourceShelfDialog extends ConsumerStatefulWidget {
  final int topicId;
  final String topicTitle;

  const ResourceShelfDialog({
    super.key,
    required this.topicId,
    required this.topicTitle,
  });

  static Future<void> show(BuildContext context, int topicId, String topicTitle) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => ResourceShelfDialog(
        topicId: topicId,
        topicTitle: topicTitle,
      ),
    );
  }

  @override
  ConsumerState<ResourceShelfDialog> createState() => _ResourceShelfDialogState();
}

class _ResourceShelfDialogState extends ConsumerState<ResourceShelfDialog> {
  bool _isAdding = false;
  final _titleController = TextEditingController();
  final _urlController = TextEditingController();
  final _notesController = TextEditingController();
  String _selectedType = 'book';

  final List<_ResourceTypeOption> _typeOptions = const [
    _ResourceTypeOption(type: 'book', label: 'Book', icon: Icons.menu_book_rounded, color: Color(0xFFF59E0B)),
    _ResourceTypeOption(type: 'video', label: 'Video', icon: Icons.play_circle_filled_rounded, color: Color(0xFFEF4444)),
    _ResourceTypeOption(type: 'article', label: 'Article', icon: Icons.article_rounded, color: Color(0xFF06B6D4)),
    _ResourceTypeOption(type: 'course', label: 'Course', icon: Icons.school_rounded, color: Color(0xFF8B5CF6)),
    _ResourceTypeOption(type: 'pdf', label: 'PDF', icon: Icons.picture_as_pdf_rounded, color: Color(0xFFF43F5E)),
    _ResourceTypeOption(type: 'doc', label: 'Doc', icon: Icons.description_rounded, color: Color(0xFF3B82F6)),
    _ResourceTypeOption(type: 'github', label: 'GitHub', icon: Icons.code_rounded, color: Color(0xFF10B981)),
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _urlController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _resetForm() {
    _titleController.clear();
    _urlController.clear();
    _notesController.clear();
    setState(() {
      _selectedType = 'book';
      _isAdding = false;
    });
  }

  Future<void> _submitAdd() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    await ref.read(topicResourcesProvider(widget.topicId).notifier).addResource(
          title: title,
          resourceType: _selectedType,
          url: _urlController.text.trim(),
          notes: _notesController.text.trim(),
        );

    _resetForm();
  }

  @override
  Widget build(BuildContext context) {
    final resourcesAsync = ref.watch(topicResourcesProvider(widget.topicId));

    return Dialog(
      backgroundColor: AppColors.darkCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.darkBorder),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
      child: Container(
        width: 680,
        constraints: const BoxConstraints(maxHeight: 650),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header Row ──────────────────────────────────────────────────
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: const Icon(Icons.shelves, color: AppColors.primaryLight, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Learning Resource Shelf',
                            style: TextStyle(
                              color: AppColors.textDarkPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                widget.topicTitle,
                                style: const TextStyle(
                                  color: AppColors.primaryLight,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'Curated books, courses, videos, and PDFs for focused topic study',
                        style: TextStyle(color: AppColors.textDarkMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textDarkSecondary, size: 20),
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Close Shelf',
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(color: AppColors.darkBorder, height: 1),
            const SizedBox(height: 16),

            // ── Shelf Progress & Add Trigger ────────────────────────────────
            resourcesAsync.maybeWhen(
              data: (items) => _buildProgressHeader(items),
              orElse: () => const SizedBox.shrink(),
            ),

            const SizedBox(height: 12),

            // ── Add Resource Form (Collapsible) ─────────────────────────────
            if (_isAdding) ...[
              _buildAddResourceForm(),
              const SizedBox(height: 16),
            ],

            // ── Resources List ──────────────────────────────────────────────
            Expanded(
              child: resourcesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                error: (e, _) => Center(
                  child: Text('Error loading resources: $e', style: const TextStyle(color: AppColors.error)),
                ),
                data: (items) {
                  if (items.isEmpty && !_isAdding) {
                    return _buildEmptyState();
                  }
                  return ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (ctx, idx) => _buildResourceItem(items[idx]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressHeader(List<ResourceModel> items) {
    final total = items.length;
    final completed = items.where((r) => r.isCompleted).length;
    final percent = total > 0 ? (completed / total) : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.sidebarBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$completed of $total resources completed',
                      style: const TextStyle(
                        color: AppColors.textDarkSecondary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${(percent * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: AppColors.primaryLight,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: percent,
                    minHeight: 5,
                    backgroundColor: AppColors.darkBorder,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _isAdding = !_isAdding;
              });
            },
            icon: Icon(_isAdding ? Icons.remove : Icons.add, size: 16),
            label: Text(_isAdding ? 'Close Form' : 'Add Resource'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isAdding ? AppColors.darkCardHover : AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddResourceForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.sidebarBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'New Learning Resource',
            style: TextStyle(
              color: AppColors.textDarkPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          // Type Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _typeOptions.map((opt) {
                final isSelected = _selectedType == opt.type;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(opt.icon, size: 14, color: isSelected ? Colors.white : opt.color),
                        const SizedBox(width: 5),
                        Text(opt.label),
                      ],
                    ),
                    selected: isSelected,
                    selectedColor: opt.color,
                    backgroundColor: AppColors.darkCard,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textDarkSecondary,
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                    onSelected: (val) {
                      if (val) setState(() => _selectedType = opt.type);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),

          // Title
          TextField(
            controller: _titleController,
            style: const TextStyle(color: AppColors.textDarkPrimary, fontSize: 13),
            decoration: const InputDecoration(
              labelText: 'Resource Title (e.g. Designing Data-Intensive Applications)',
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),

          // URL
          TextField(
            controller: _urlController,
            style: const TextStyle(color: AppColors.textDarkPrimary, fontSize: 13),
            decoration: const InputDecoration(
              labelText: 'URL or Link (e.g. https://... or file:///...)',
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),

          // Notes
          TextField(
            controller: _notesController,
            style: const TextStyle(color: AppColors.textDarkPrimary, fontSize: 13),
            decoration: const InputDecoration(
              labelText: 'Notes or Chapter Scope (e.g. Read Chapters 5 & 6)',
              isDense: true,
            ),
          ),
          const SizedBox(height: 14),

          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _resetForm,
                child: const Text('Cancel', style: TextStyle(color: AppColors.textDarkMuted)),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _submitAdd,
                icon: const Icon(Icons.bookmark_add, size: 16),
                label: const Text('Save to Shelf'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResourceItem(ResourceModel item) {
    final opt = _typeOptions.firstWhere(
      (o) => o.type == item.resourceType,
      orElse: () => _typeOptions[2], // default article
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.sidebarBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: item.isCompleted
              ? AppColors.success.withValues(alpha: 0.3)
              : AppColors.darkBorder,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Completion Checkbox
          Padding(
            padding: const EdgeInsets.only(top: 2, right: 8),
            child: Checkbox(
              value: item.isCompleted,
              activeColor: AppColors.success,
              checkColor: Colors.white,
              visualDensity: VisualDensity.compact,
              onChanged: (val) {
                if (val != null) {
                  ref
                      .read(topicResourcesProvider(widget.topicId).notifier)
                      .toggleComplete(item.id, val);
                }
              },
            ),
          ),

          // Type Icon Badge
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: opt.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: opt.color.withValues(alpha: 0.25)),
            ),
            child: Icon(opt.icon, size: 16, color: opt.color),
          ),
          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: TextStyle(
                          color: item.isCompleted ? AppColors.textDarkMuted : AppColors.textDarkPrimary,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: opt.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        opt.label.toUpperCase(),
                        style: TextStyle(
                          color: opt.color,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
                ),
                if (item.url != null && item.url!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: item.url!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Copied to clipboard: ${item.url}'),
                          duration: const Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.link, size: 13, color: AppColors.accent),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              item.url!,
                              style: const TextStyle(
                                color: AppColors.accent,
                                fontSize: 11.5,
                                decoration: TextDecoration.underline,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.copy, size: 11, color: AppColors.textDarkMuted),
                        ],
                      ),
                    ),
                  ),
                ],
                if (item.notes != null && item.notes!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.darkCardHover,
                      borderRadius: BorderRadius.circular(6),
                      border: const Border(
                        left: BorderSide(color: AppColors.primaryLight, width: 2.5),
                      ),
                    ),
                    child: Text(
                      item.notes!,
                      style: const TextStyle(
                        color: AppColors.textDarkSecondary,
                        fontSize: 11.5,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Delete button
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 16),
            color: AppColors.error.withValues(alpha: 0.6),
            tooltip: 'Delete resource',
            onPressed: () {
              ref
                  .read(topicResourcesProvider(widget.topicId).notifier)
                  .deleteResource(item.id);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.sidebarBg,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.darkBorder),
            ),
            child: const Icon(Icons.menu_book_outlined, size: 28, color: AppColors.textDarkMuted),
          ),
          const SizedBox(height: 14),
          const Text(
            'Resource shelf is empty',
            style: TextStyle(
              color: AppColors.textDarkPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Add books, articles, video courses, or PDFs to curate study material for this topic.',
            style: TextStyle(color: AppColors.textDarkMuted, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _isAdding = true;
              });
            },
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add First Resource'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResourceTypeOption {
  final String type;
  final String label;
  final IconData icon;
  final Color color;

  const _ResourceTypeOption({
    required this.type,
    required this.label,
    required this.icon,
    required this.color,
  });
}
