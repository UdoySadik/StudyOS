import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../roadmap/application/roadmap_provider.dart';
import '../../roadmap/domain/roadmap_models.dart';
import '../application/notes_provider.dart';
import '../../../core/theme/app_theme.dart';

class NotesPage extends ConsumerStatefulWidget {
  const NotesPage({super.key});

  @override
  ConsumerState<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends ConsumerState<NotesPage> {
  int? _selectedTopicId;
  String? _selectedTopicTitle;
  final _noteController = TextEditingController();
  bool _isEditing = true;
  bool _isSaving = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedRoadmapId = ref.watch(selectedRoadmapIdProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: Row(
        children: [
          // Left Pane: Topic Explorer
          _buildTopicExplorer(selectedRoadmapId),
          const VerticalDivider(width: 1, color: AppColors.darkBorder),
          // Right Pane: Editor / Previewer
          Expanded(
            child: _selectedTopicId == null
                ? _buildNoNotesSelectedState()
                : _buildNotesWorkspace(_selectedTopicId!),
          ),
        ],
      ),
    );
  }

  Widget _buildTopicExplorer(int? selectedRoadmapId) {
    if (selectedRoadmapId == null) {
      return Container(
        width: 260,
        padding: const EdgeInsets.all(16),
        child: const Center(
          child: Text(
            'Select a roadmap to browse topics.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textDarkSecondary),
          ),
        ),
      );
    }

    final phasesAsync = ref.watch(phaseNotifierProvider(selectedRoadmapId));

    return Container(
      width: 280,
      color: AppColors.sidebarBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 12),
            child: Text(
              'Topics & Notes',
              style: TextStyle(
                color: AppColors.textDarkPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.darkBorder),
          Expanded(
            child: phasesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (phases) {
                if (phases.isEmpty) {
                  return const Center(
                    child: Text('No phases found', style: TextStyle(color: AppColors.textDarkSecondary)),
                  );
                }
                return ListView.builder(
                  itemCount: phases.length,
                  itemBuilder: (context, index) {
                    final phase = phases[index];
                    return _buildPhaseGroup(phase);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseGroup(PhaseModel phase) {
    final topicsAsync = ref.watch(topicNotifierProvider(phase.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: Text(
            phase.title.toUpperCase(),
            style: const TextStyle(
              color: AppColors.textDarkMuted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
        ),
        topicsAsync.when(
          loading: () => const SizedBox(),
          error: (e, _) => const SizedBox(),
          data: (topics) => Column(
            children: topics.map((topic) {
              final isSelected = _selectedTopicId == topic.id;
              return ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                title: Text(
                  topic.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isSelected ? AppColors.primary : AppColors.textDarkSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
                leading: Icon(
                  Icons.sticky_note_2_outlined,
                  size: 16,
                  color: isSelected ? AppColors.primary : AppColors.textDarkMuted,
                ),
                onTap: () {
                  setState(() {
                    _selectedTopicId = topic.id;
                    _selectedTopicTitle = topic.title;
                  });
                },
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildNoNotesSelectedState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.sticky_note_2_outlined, size: 64, color: AppColors.textDarkMuted),
          SizedBox(height: 16),
          Text(
            'No Topic Selected',
            style: TextStyle(
              color: AppColors.textDarkPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Select a topic from the sidebar explorer to view or write study notes.',
            style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesWorkspace(int topicId) {
    final noteAsync = ref.watch(topicNoteNotifierProvider(topicId));

    return noteAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (note) {
        // Initial setup of text controller
        if (note != null && _noteController.text != note.content && !_isSaving) {
          _noteController.text = note.content;
        }

        return Scaffold(
          backgroundColor: AppColors.darkBg,
          appBar: AppBar(
            backgroundColor: AppColors.darkBg,
            elevation: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Study Notes',
                  style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 11),
                ),
                Text(
                  _selectedTopicTitle ?? '',
                  style: const TextStyle(
                    color: AppColors.textDarkPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            actions: [
              // Auto-save Status Indicator
              Row(
                children: [
                  Icon(
                    _isSaving ? Icons.sync : Icons.cloud_done_outlined,
                    size: 14,
                    color: _isSaving ? AppColors.warning : AppColors.success,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _isSaving ? 'Saving...' : 'Saved',
                    style: TextStyle(
                      color: _isSaving ? AppColors.warning : AppColors.success,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              // View / Edit Toggle buttons
              ToggleButtons(
                borderRadius: BorderRadius.circular(6),
                selectedColor: Colors.white,
                fillColor: AppColors.primary,
                color: AppColors.textDarkSecondary,
                constraints: const BoxConstraints(minHeight: 28, minWidth: 54),
                isSelected: [_isEditing, !_isEditing],
                onPressed: (idx) {
                  setState(() {
                    _isEditing = idx == 0;
                  });
                },
                children: const [
                  Text('Edit', style: TextStyle(fontSize: 12)),
                  Text('Preview', style: TextStyle(fontSize: 12)),
                ],
              ),
              const SizedBox(width: 16),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: _isEditing
                ? Container(
                    decoration: BoxDecoration(
                      color: AppColors.darkCard,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.darkBorder),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: _noteController,
                      maxLines: null,
                      expands: true,
                      style: const TextStyle(
                        color: AppColors.textDarkPrimary,
                        fontFamily: 'Courier',
                        fontSize: 14,
                        height: 1.5,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Write notes here using markdown...',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        fillColor: Colors.transparent,
                        filled: false,
                      ),
                      onChanged: (val) {
                        setState(() {
                          _isSaving = true;
                        });
                        ref.read(topicNoteNotifierProvider(topicId).notifier).saveNoteDebounced(val);
                        // Stop saving spinner after debounce fires
                        Future.delayed(const Duration(milliseconds: 600), () {
                          if (mounted) {
                            setState(() {
                              _isSaving = false;
                            });
                          }
                        });
                      },
                    ),
                  )
                : Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.darkCard,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.darkBorder),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Markdown(
                      data: _noteController.text,
                      styleSheet: MarkdownStyleSheet(
                        p: const TextStyle(color: AppColors.textDarkPrimary, fontSize: 14, height: 1.6),
                        h1: const TextStyle(color: AppColors.primary, fontSize: 20, fontWeight: FontWeight.bold, height: 1.8),
                        h2: const TextStyle(color: AppColors.accent, fontSize: 17, fontWeight: FontWeight.bold, height: 1.6),
                        h3: const TextStyle(color: AppColors.textDarkPrimary, fontSize: 15, fontWeight: FontWeight.bold, height: 1.5),
                        code: const TextStyle(backgroundColor: AppColors.darkBg, color: AppColors.warning, fontFamily: 'Courier'),
                        codeblockDecoration: BoxDecoration(
                          color: AppColors.darkBg,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.darkBorder),
                        ),
                      ),
                    ),
                  ),
          ),
        );
      },
    );
  }
}
