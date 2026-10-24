import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../roadmap/application/roadmap_provider.dart';
import '../../roadmap/domain/roadmap_models.dart';
import '../application/notes_provider.dart';
import '../../timer/application/timer_provider.dart';
import '../../resources/presentation/resource_shelf_dialog.dart';
import '../../recall/presentation/recall_hub_page.dart';
import 'note_ai_dialog.dart';
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
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isEditing = true;
  bool _isSaving = false;

  @override
  void dispose() {
    _noteController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedRoadmapId = ref.watch(selectedRoadmapIdProvider);
    final roadmapsAsync = ref.watch(roadmapNotifierProvider);

    // Auto-select first roadmap if none is selected yet
    if (selectedRoadmapId == null) {
      roadmapsAsync.whenData((roadmaps) {
        if (roadmaps.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && ref.read(selectedRoadmapIdProvider) == null) {
              ref.read(selectedRoadmapIdProvider.notifier).state = roadmaps.first.id;
            }
          });
        }
      });
    }

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
        width: 280,
        padding: const EdgeInsets.all(24),
        color: AppColors.sidebarBg,
        child: const Center(
          child: Text(
            'Select or create a roadmap to browse topics.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textDarkSecondary),
          ),
        ),
      );
    }

    final phasesAsync = ref.watch(phaseNotifierProvider(selectedRoadmapId));
    final allNotesAsync = ref.watch(allNotesProvider);
    final allNotes = allNotesAsync.asData?.value ?? [];

    return Container(
      width: 280,
      color: AppColors.sidebarBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Text(
              'Topics & Notes',
              style: TextStyle(
                color: AppColors.textDarkPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          // Search input bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.darkCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.darkBorder),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val.trim()),
                style: const TextStyle(color: AppColors.textDarkPrimary, fontSize: 12),
                decoration: InputDecoration(
                  hintText: 'Search topics or note content...',
                  hintStyle: const TextStyle(color: AppColors.textDarkMuted, fontSize: 11),
                  prefixIcon: const Icon(Icons.search, size: 16, color: AppColors.textDarkMuted),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, size: 14, color: AppColors.textDarkMuted),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
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
                    return _buildPhaseGroup(phase, allNotes);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseGroup(PhaseModel phase, List<dynamic> allNotes) {
    final topicsAsync = ref.watch(topicNotifierProvider(phase.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        topicsAsync.when(
          loading: () => const SizedBox(),
          error: (e, _) => const SizedBox(),
          data: (topics) {
            // Build set of topic IDs where note content contains query
            final noteMatchedTopicIds = <int>{};
            if (_searchQuery.isNotEmpty) {
              final queryLower = _searchQuery.toLowerCase();
              for (final note in allNotes) {
                if (note.content != null &&
                    note.content.toString().toLowerCase().contains(queryLower)) {
                  noteMatchedTopicIds.add(note.topicId as int);
                }
              }
            }

            final filteredTopics = _searchQuery.isEmpty
                ? topics
                : topics.where((t) {
                    final titleMatch = t.title.toLowerCase().contains(_searchQuery.toLowerCase());
                    final noteMatch = noteMatchedTopicIds.contains(t.id);
                    return titleMatch || noteMatch;
                  }).toList();

            if (_searchQuery.isNotEmpty && filteredTopics.isEmpty) {
              return const SizedBox();
            }

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
                ...filteredTopics.map((topic) {
                  final isSelected = _selectedTopicId == topic.id;
                  final matchedInNoteOnly = _searchQuery.isNotEmpty &&
                      !topic.title.toLowerCase().contains(_searchQuery.toLowerCase()) &&
                      noteMatchedTopicIds.contains(topic.id);

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
                    subtitle: matchedInNoteOnly
                        ? const Text(
                            'Matched inside note',
                            style: TextStyle(color: AppColors.accent, fontSize: 10),
                          )
                        : null,
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
                }),
                const SizedBox(height: 8),
              ],
            );
          },
        ),
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
    final timerState = ref.watch(studyTimerProvider);
    final statsAsync = ref.watch(topicStudyStatsProvider(topicId));

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
                Row(
                  children: [
                    const Text(
                      'Study Notes',
                      style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 11),
                    ),
                    statsAsync.maybeWhen(
                      data: (stats) {
                        if (stats.totalSeconds == 0) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Text(
                            '•  ⏱️ ${stats.formattedDuration} studied',
                            style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        );
                      },
                      orElse: () => const SizedBox.shrink(),
                    ),
                  ],
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
              // Study Stopwatch Button
              OutlinedButton.icon(
                icon: Icon(
                  timerState.activeTopicId == topicId && timerState.isRunning
                      ? Icons.pause
                      : Icons.timer_outlined,
                  size: 14,
                  color: timerState.activeTopicId == topicId ? AppColors.success : AppColors.primary,
                ),
                label: Text(
                  timerState.activeTopicId == topicId
                      ? (timerState.isRunning ? 'Timer: ${timerState.formattedTime}' : 'Paused')
                      : 'Study Topic',
                  style: TextStyle(
                    fontSize: 12,
                    color: timerState.activeTopicId == topicId ? AppColors.success : AppColors.primary,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: timerState.activeTopicId == topicId
                        ? AppColors.success.withValues(alpha: 0.5)
                        : AppColors.primary.withValues(alpha: 0.4),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
                onPressed: () {
                  if (timerState.activeTopicId == topicId) {
                    if (timerState.isRunning) {
                      ref.read(studyTimerProvider.notifier).pauseTimer();
                    } else {
                      ref.read(studyTimerProvider.notifier).resumeTimer();
                    }
                  } else {
                    ref.read(studyTimerProvider.notifier).startTimer(
                          topicId,
                          _selectedTopicTitle ?? 'Topic Study',
                        );
                  }
                },
              ),
              const SizedBox(width: 8),

              // Resource Shelf Button
              OutlinedButton.icon(
                icon: const Icon(Icons.shelves, size: 14, color: Color(0xFFF59E0B)),
                label: const Text(
                  'Resources',
                  style: TextStyle(fontSize: 12, color: Color(0xFFF59E0B)),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
                onPressed: () {
                  ResourceShelfDialog.show(
                    context,
                    topicId,
                    _selectedTopicTitle ?? 'Topic',
                  );
                },
              ),
              const SizedBox(width: 8),

              // AI Recall Generator Button
              OutlinedButton.icon(
                key: const Key('notes_ai_recall_btn'),
                icon: const Icon(Icons.psychology_outlined, size: 14, color: AppColors.primaryLight),
                label: const Text(
                  'AI Recall',
                  style: TextStyle(fontSize: 12, color: AppColors.primaryLight),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.primary.withValues(alpha: 0.4)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
                onPressed: () {
                  GenerateRecallDialog.show(
                    context,
                    preselectedTopicId: topicId,
                    preselectedTopicTitle: _selectedTopicTitle,
                  );
                },
              ),
              const SizedBox(width: 8),

              // AI Assistant (Summarize & Explainer) Button
              OutlinedButton.icon(
                key: const Key('notes_ai_assistant_btn'),
                icon: const Icon(Icons.auto_awesome_rounded, size: 14, color: Color(0xFF06B6D4)),
                label: const Text(
                  'AI Assistant',
                  style: TextStyle(fontSize: 12, color: Color(0xFF06B6D4)),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: const Color(0xFF06B6D4).withValues(alpha: 0.4)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
                onPressed: () {
                  NoteAIDialog.show(
                    context,
                    topicId: topicId,
                    topicTitle: _selectedTopicTitle,
                    noteContent: _noteController.text,
                    onInsertAtTop: (text) {
                      setState(() {
                        _noteController.text = '$text\n\n${_noteController.text}';
                        _isSaving = true;
                      });
                      ref.read(topicNoteNotifierProvider(topicId).notifier).saveNoteDebounced(_noteController.text);
                      Future.delayed(const Duration(milliseconds: 600), () {
                        if (mounted) setState(() => _isSaving = false);
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: Color(0xFF10B981),
                          content: Text('Summary inserted at the top of note!'),
                        ),
                      );
                    },
                    onAppendToEnd: (text) {
                      setState(() {
                        _noteController.text = '${_noteController.text.trim()}\n\n$text\n';
                        _isSaving = true;
                      });
                      ref.read(topicNoteNotifierProvider(topicId).notifier).saveNoteDebounced(_noteController.text);
                      Future.delayed(const Duration(milliseconds: 600), () {
                        if (mounted) setState(() => _isSaving = false);
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: Color(0xFF10B981),
                          content: Text('Content appended to note!'),
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(width: 16),
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
