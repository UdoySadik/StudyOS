import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../application/documents_provider.dart';
import '../domain/document_models.dart';
import 'add_document_dialog.dart';

class DocumentHubPage extends ConsumerStatefulWidget {
  const DocumentHubPage({super.key});

  @override
  ConsumerState<DocumentHubPage> createState() => _DocumentHubPageState();
}

class _DocumentHubPageState extends ConsumerState<DocumentHubPage> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _searchController = TextEditingController();
  final _queryController = TextEditingController();
  int _selectedTopK = 3;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _queryController.dispose();
    super.dispose();
  }

  void _runRagQuery([String? predefinedQuery]) {
    final queryText = predefinedQuery ?? _queryController.text.trim();
    if (queryText.isEmpty) return;

    if (predefinedQuery != null) {
      _queryController.text = predefinedQuery;
    }

    final selectedDocId = ref.read(selectedDocumentIdProvider);
    final docIds = selectedDocId != null ? [selectedDocId] : null;

    ref.read(ragNotifierProvider.notifier).queryRAG(
          query: queryText,
          documentIds: docIds,
          topK: _selectedTopK,
        );

    // Switch to RAG tab if not already on it
    if (_tabController.index != 0) {
      _tabController.animateTo(0);
    }
  }

  Color _getDocTypeColor(String docType) {
    switch (docType.toLowerCase()) {
      case 'paper':
        return const Color(0xFF06B6D4);
      case 'docs':
        return const Color(0xFF10B981);
      case 'notes':
        return const Color(0xFFF59E0B);
      case 'textbook':
      default:
        return const Color(0xFF6366F1);
    }
  }

  IconData _getDocTypeIcon(String docType) {
    switch (docType.toLowerCase()) {
      case 'paper':
        return Icons.article_rounded;
      case 'docs':
        return Icons.description_rounded;
      case 'notes':
        return Icons.edit_note_rounded;
      case 'textbook':
      default:
        return Icons.menu_book_rounded;
    }
  }

  Color _getRelevanceColor(double score) {
    if (score >= 0.70) return AppColors.success;
    if (score >= 0.40) return AppColors.accent;
    return AppColors.warning;
  }

  @override
  Widget build(BuildContext context) {
    final docsAsync = ref.watch(documentsNotifierProvider);
    final selectedDocId = ref.watch(selectedDocumentIdProvider);
    final ragState = ref.watch(ragNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top Header ───────────────────────────────────────────────
              _buildHeader(context, docsAsync.valueOrNull?.length ?? 0),
              const SizedBox(height: 20),

              // ── Main Two-Column Master-Detail Layout ──────────────────────
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Shelf Panel: Document Library
                    SizedBox(
                      width: 380,
                      child: _buildDocumentsShelf(context, docsAsync, selectedDocId),
                    ),
                    const SizedBox(width: 20),

                    // Right Panel: RAG Assistant & Chunks Inspector
                    Expanded(
                      child: _buildRightPanel(selectedDocId, ragState),
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

  Widget _buildHeader(BuildContext context, int docCount) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          ),
          child: const Icon(Icons.menu_book_rounded, color: AppColors.primaryLight, size: 28),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 6,
                children: [
                  const Text(
                    'Document Intelligence & RAG Shelf',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDarkPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bolt_rounded, size: 14, color: AppColors.success),
                        SizedBox(width: 4),
                        Text(
                          'Offline RAG Active',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.success),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Index textbook chapters, research papers, and technical docs with local hybrid chunk retrieval and citations.',
                style: TextStyle(fontSize: 13, color: AppColors.textDarkSecondary),
              ),
            ],
          ),
        ),
        ElevatedButton.icon(
          key: const Key('index_document_button'),
          onPressed: () => AddDocumentDialog.show(context),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Index Document'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentsShelf(
    BuildContext context,
    AsyncValue<List<DocumentModel>> docsAsync,
    int? selectedDocId,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        children: [
          // Shelf Header & Search
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'INDEXED LIBRARY',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                        color: AppColors.textDarkSecondary,
                      ),
                    ),
                    docsAsync.maybeWhen(
                      data: (docs) => Text(
                        '${docs.length} docs',
                        style: const TextStyle(fontSize: 12, color: AppColors.textDarkMuted),
                      ),
                      orElse: () => const SizedBox.shrink(),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  key: const Key('documents_search_field'),
                  controller: _searchController,
                  onChanged: (val) {
                    ref.read(documentFilterProvider.notifier).update((s) => s.copyWith(searchQuery: val));
                  },
                  style: const TextStyle(color: AppColors.textDarkPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Search indexed documents...',
                    hintStyle: const TextStyle(color: AppColors.textDarkMuted, fontSize: 13),
                    prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.textDarkSecondary),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 16, color: AppColors.textDarkSecondary),
                            onPressed: () {
                              _searchController.clear();
                              ref.read(documentFilterProvider.notifier).update((s) => s.copyWith(searchQuery: ''));
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.darkCard,
                    isDense: true,
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
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.darkBorder, height: 1),

          // Document List
          Expanded(
            child: docsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryLight),
              ),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('Error loading documents: $err', style: const TextStyle(color: AppColors.error, fontSize: 12)),
                ),
              ),
              data: (docs) {
                if (docs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.auto_stories_rounded, size: 48, color: AppColors.textDarkMuted.withValues(alpha: 0.5)),
                          const SizedBox(height: 12),
                          const Text(
                            'No documents indexed yet',
                            style: TextStyle(color: AppColors.textDarkSecondary, fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Index papers or textbook chapters to start local retrieval and citation Q&A.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textDarkMuted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, index) {
                    final doc = docs[index];
                    final isSelected = selectedDocId == doc.id;
                    final docColor = _getDocTypeColor(doc.docType);

                    return InkWell(
                      key: Key('document_card_${doc.id}'),
                      onTap: () {
                        if (isSelected) {
                          ref.read(selectedDocumentIdProvider.notifier).state = null;
                        } else {
                          ref.read(selectedDocumentIdProvider.notifier).state = doc.id;
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary.withValues(alpha: 0.12) : AppColors.darkCard,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : AppColors.darkBorder,
                            width: isSelected ? 1.5 : 1.0,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: docColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(_getDocTypeIcon(doc.docType), color: docColor, size: 18),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        doc.title,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                          color: AppColors.textDarkPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: docColor.withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              doc.docType.toUpperCase(),
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                color: docColor,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              '${doc.totalChunks} chunks • ${doc.totalPages} ${doc.totalPages == 1 ? 'page' : 'pages'}',
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(fontSize: 11, color: AppColors.textDarkSecondary),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert_rounded, size: 18, color: AppColors.textDarkMuted),
                                  color: AppColors.darkSurface,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    side: const BorderSide(color: AppColors.darkBorder),
                                  ),
                                  itemBuilder: (ctx) => [
                                    PopupMenuItem(
                                      value: 'scope',
                                      child: Row(
                                        children: [
                                          Icon(
                                            isSelected ? Icons.check_circle_rounded : Icons.filter_center_focus_rounded,
                                            size: 16,
                                            color: AppColors.primaryLight,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(isSelected ? 'Unscope Q&A' : 'Scope Q&A Here', style: const TextStyle(fontSize: 13, color: AppColors.textDarkPrimary)),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.error),
                                          SizedBox(width: 8),
                                          Text('Delete Document', style: TextStyle(fontSize: 13, color: AppColors.error)),
                                        ],
                                      ),
                                    ),
                                  ],
                                  onSelected: (val) async {
                                    if (val == 'scope') {
                                      ref.read(selectedDocumentIdProvider.notifier).state = isSelected ? null : doc.id;
                                    } else if (val == 'delete') {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (c) => AlertDialog(
                                          backgroundColor: AppColors.darkSurface,
                                          title: const Text('Delete Document?', style: TextStyle(color: AppColors.textDarkPrimary)),
                                          content: Text('Remove "${doc.title}" and all indexed chunks?', style: const TextStyle(color: AppColors.textDarkSecondary)),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.of(c).pop(false),
                                              child: const Text('Cancel'),
                                            ),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                                              onPressed: () => Navigator.of(c).pop(true),
                                              child: const Text('Delete', style: TextStyle(color: Colors.white)),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirm == true) {
                                        if (selectedDocId == doc.id) {
                                          ref.read(selectedDocumentIdProvider.notifier).state = null;
                                        }
                                        await ref.read(documentsNotifierProvider.notifier).deleteDocument(doc.id);
                                      }
                                    }
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRightPanel(int? selectedDocId, RAGState ragState) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tab Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.darkBorder)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  indicatorColor: AppColors.primary,
                  indicatorWeight: 3,
                  labelColor: AppColors.primaryLight,
                  unselectedLabelColor: AppColors.textDarkSecondary,
                  tabs: const [
                    Tab(
                      child: Row(
                        children: [
                          Icon(Icons.auto_awesome_rounded, size: 16),
                          SizedBox(width: 8),
                          Text('RAG Q&A Assistant', style: TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        children: [
                          Icon(Icons.segment_rounded, size: 16),
                          SizedBox(width: 8),
                          Text('Document Chunks Inspector', style: TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
                if (selectedDocId != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.filter_alt_rounded, size: 14, color: AppColors.primaryLight),
                        const SizedBox(width: 4),
                        const Text(
                          'Scoped to Selected Doc',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryLight),
                        ),
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: () => ref.read(selectedDocumentIdProvider.notifier).state = null,
                          child: const Icon(Icons.close_rounded, size: 14, color: AppColors.primaryLight),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildRagTab(selectedDocId, ragState),
                _buildChunksInspectorTab(selectedDocId),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRagTab(int? selectedDocId, RAGState ragState) {
    final List<String> suggestions = [
      'What is synchronous vs asynchronous replication?',
      'How are split votes avoided during leader election?',
      'What are the key guarantees of Raft consensus?',
      'Explain leader-based replication architecture',
    ];

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Query Input Area
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.darkCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.darkBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        key: const Key('rag_query_input_field'),
                        controller: _queryController,
                        onSubmitted: (_) => _runRagQuery(),
                        style: const TextStyle(color: AppColors.textDarkPrimary, fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: 'Ask a question based on your indexed textbooks and papers...',
                          hintStyle: TextStyle(color: AppColors.textDarkMuted, fontSize: 14),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    DropdownButton<int>(
                      value: _selectedTopK,
                      dropdownColor: AppColors.darkSurface,
                      underline: const SizedBox.shrink(),
                      items: const [
                        DropdownMenuItem(value: 2, child: Text('Top 2 chunks', style: TextStyle(fontSize: 12, color: AppColors.textDarkSecondary))),
                        DropdownMenuItem(value: 3, child: Text('Top 3 chunks', style: TextStyle(fontSize: 12, color: AppColors.textDarkSecondary))),
                        DropdownMenuItem(value: 5, child: Text('Top 5 chunks', style: TextStyle(fontSize: 12, color: AppColors.textDarkSecondary))),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedTopK = val);
                      },
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      key: const Key('rag_ask_button'),
                      onPressed: ragState.isLoading ? null : () => _runRagQuery(),
                      icon: ragState.isLoading
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.search_rounded, size: 16),
                      label: Text(ragState.isLoading ? 'Retrieving...' : 'Ask RAG'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Suggestion chips
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: suggestions.map((s) {
                    return ActionChip(
                      label: Text(s, style: const TextStyle(fontSize: 11, color: AppColors.textDarkSecondary)),
                      backgroundColor: AppColors.darkSurface,
                      side: const BorderSide(color: AppColors.darkBorder),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      onPressed: () => _runRagQuery(s),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Query Result / Empty / Loading State
          Expanded(
            child: ragState.isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: AppColors.primaryLight),
                        SizedBox(height: 16),
                        Text(
                          'Searching indexed chunks and synthesizing answers with citations...',
                          style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : ragState.result != null
                    ? _buildRagAnswerView(ragState.result!)
                    : _buildRagInitialPlaceholder(),
          ),
        ],
      ),
    );
  }

  Widget _buildRagInitialPlaceholder() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.manage_search_rounded, size: 48, color: AppColors.primaryLight),
            ),
            const SizedBox(height: 16),
            const Text(
              'Ask Any Question Across Your Study Documents',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDarkPrimary),
            ),
            const SizedBox(height: 8),
            const SizedBox(
              width: 480,
              child: Text(
                'StudyOS extracts relevant chunks using hybrid vector + keyword matching, synthesizes an answer, and shows exact page citations.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.textDarkSecondary, height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRagAnswerView(RAGQueryResult result) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Model & Query Header Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.darkCard,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.darkBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.help_outline_rounded, size: 18, color: AppColors.primaryLight),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    result.query,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDarkPrimary),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    result.modelUsed,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.accent),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Answer Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.darkCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.darkBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'SYNTHESIZED ANSWER',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                        color: AppColors.textDarkSecondary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 16, color: AppColors.textDarkSecondary),
                      tooltip: 'Copy Answer',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: result.answerMarkdown));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Answer copied to clipboard!')),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                MarkdownBody(
                  data: result.answerMarkdown,
                  selectable: true,
                  styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                    p: const TextStyle(fontSize: 14, height: 1.5, color: AppColors.textDarkPrimary),
                    h1: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDarkPrimary),
                    h2: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDarkPrimary),
                    h3: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primaryLight),
                    blockquote: const TextStyle(color: AppColors.textDarkSecondary, fontStyle: FontStyle.italic),
                    blockquoteDecoration: BoxDecoration(
                      color: AppColors.darkSurface,
                      border: const Border(left: BorderSide(color: AppColors.primary, width: 3)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Citations List
          if (result.citations.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.format_quote_rounded, size: 18, color: AppColors.accent),
                const SizedBox(width: 6),
                Text(
                  'Supporting Evidence & Citations (${result.citations.length})',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDarkPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...result.citations.map((c) {
              final relevanceColor = _getRelevanceColor(c.relevanceScore);
              final pct = (c.relevanceScore * 100).toInt();

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.darkCard,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.darkBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(Icons.bookmark_rounded, size: 16, color: AppColors.primaryLight),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '${c.documentTitle} • p. ${c.pageNumber}',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: AppColors.textDarkPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: relevanceColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: relevanceColor.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            '$pct% Relevance',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: relevanceColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.darkSurface,
                        borderRadius: BorderRadius.circular(6),
                        border: const Border(left: BorderSide(color: AppColors.accent, width: 3)),
                      ),
                      child: Text(
                        '"${c.snippet}"',
                        style: const TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: AppColors.textDarkSecondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildChunksInspectorTab(int? selectedDocId) {
    if (selectedDocId == null) {
      return Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.touch_app_rounded, size: 48, color: AppColors.textDarkMuted.withValues(alpha: 0.5)),
              const SizedBox(height: 12),
              const Text(
                'Select a Document to Inspect Chunks',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDarkPrimary),
              ),
              const SizedBox(height: 6),
              const Text(
                'Click any document in the left library shelf to inspect its sliding-window RAG chunks.',
                style: TextStyle(fontSize: 12, color: AppColors.textDarkSecondary),
              ),
            ],
          ),
        ),
      );
    }

    final detailAsync = ref.watch(documentDetailProvider(selectedDocId));

    return detailAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryLight)),
      error: (err, _) => Center(child: Text('Error loading chunks: $err', style: const TextStyle(color: AppColors.error))),
      data: (doc) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doc.title,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDarkPrimary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Total Chunks: ${doc.chunks.length} • Total Pages: ${doc.totalPages}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textDarkSecondary),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${doc.chunks.fold<int>(0, (sum, c) => sum + c.wordCount)} total words',
                      style: const TextStyle(fontSize: 11, color: AppColors.primaryLight, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const Divider(color: AppColors.darkBorder, height: 24),

              // Chunks List
              Expanded(
                child: ListView.separated(
                  itemCount: doc.chunks.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (ctx, idx) {
                    final chunk = doc.chunks[idx];
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.darkCard,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.darkBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Chunk #${chunk.chunkIndex + 1}',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryLight),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Page ${chunk.pageNumber}',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textDarkSecondary),
                                  ),
                                ],
                              ),
                              Text(
                                '${chunk.wordCount} words',
                                style: const TextStyle(fontSize: 11, color: AppColors.textDarkMuted),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.darkSurface,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              chunk.content,
                              style: const TextStyle(
                                fontSize: 12,
                                height: 1.4,
                                color: AppColors.textDarkPrimary,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
