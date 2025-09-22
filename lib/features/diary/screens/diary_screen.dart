// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:moodscope/core/utils/toast_utils.dart';
import 'package:moodscope/features/diary/widgets/add_diary_dialog.dart';
import 'package:moodscope/features/diary/widgets/diary_entry_card.dart';
import 'package:moodscope/features/emotion_detection/models/emotion_entry.dart';
import 'package:moodscope/features/emotion_detection/providers/emotion_provider.dart';
import 'package:moodscope/features/emotion_detection/widgets/emotion_entry_card.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../providers/diary_provider.dart';
import '../models/diary_entry.dart';

class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedMoodFilter = 'all';
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _showAddDiaryDialog({DiaryEntry? entry}) {
    showDialog(
      context: context,
      builder: (context) => AddDiaryDialog(
        entry: entry,
        onSave: (title, content, mood, tags) async {
          if (!mounted) return;

          final diaryProvider = context.read<DiaryProvider>();
          bool success;

          if (entry != null) {
            // Edit existing entry
            final updatedEntry = entry.copyWith(
              title: title,
              content: content,
              mood: mood,
              tags: tags,
            );
            success = await diaryProvider.updateDiaryEntry(updatedEntry);
          } else {
            // Add new entry
            success = await diaryProvider.addDiaryEntry(
              title: title,
              content: content,
              mood: mood,
              tags: tags,
            );
          }

          if (success && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  entry != null
                      ? 'Diary entry updated! ${AppConstants.emotionEmojis[mood] ?? ''}'
                      : 'Diary entry saved! ${AppConstants.emotionEmojis[mood] ?? ''}',
                ),
                backgroundColor: AppTheme.primaryColor,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }
        },
      ),
    );
  }

  void _showEditEmotionNoteDialog(EmotionEntry entry) {
    final noteController = TextEditingController(text: entry.note ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Note'),
        content: TextField(
          controller: noteController,
          decoration: const InputDecoration(
            hintText: 'Add your thoughts...',
            border: OutlineInputBorder(),
          ),
          maxLines: 4,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final emotionProvider = context.read<EmotionProvider>();
              final success = await emotionProvider.updateEmotionEntry(
                entry.copyWith(
                  note: noteController.text.trim().isEmpty
                      ? null
                      : noteController.text.trim(),
                ),
              );

              if (success && mounted) {
                Navigator.of(context).pop();
                ToastUtils.showSuccessToast(
                  message: 'Emotion entry updated',
                  context: context,
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingLarge),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Emotion Diary',
                              style: Theme.of(context).textTheme.displaySmall
                                  ?.copyWith(
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Track your emotional journey',
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor.withAlpha(
                                (0.3 * 255).toInt(),
                              ),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: IconButton(
                          onPressed: () => _showAddDiaryDialog(),
                          icon: const Icon(
                            Icons.add_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            padding: const EdgeInsets.all(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
                .animate()
                .slideY(begin: -0.5, duration: 600.ms, curve: Curves.easeOut)
                .fadeIn(),

            // Tab Bar
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingLarge,
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: AppTheme.primaryColor,
                unselectedLabelColor: AppTheme.textTertiary,
                indicatorColor: AppTheme.primaryColor,
                tabs: const [
                  Tab(text: 'Diary Entries'),
                  Tab(text: 'Emotion Entries'),
                ],
              ),
            ),

            // Search and Filter Section
            Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.paddingLarge,
                  ),
                  child: Column(
                    children: [
                      // Search Bar
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(
                                (0.05 * 255).toInt(),
                              ),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Search entries...',
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              color: AppTheme.textSecondary,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            hintStyle: TextStyle(
                              color: AppTheme.textTertiary,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Mood Filter
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _MoodFilterChip(
                              label: 'All',
                              emoji: '📖',
                              isSelected: _selectedMoodFilter == 'all',
                              onSelected: () =>
                                  setState(() => _selectedMoodFilter = 'all'),
                            ),
                            ...AppConstants.emotionLabels.map(
                              (emotion) => _MoodFilterChip(
                                label: emotion.toUpperCase(),
                                emoji:
                                    AppConstants.emotionEmojis[emotion] ?? '😐',
                                isSelected: _selectedMoodFilter == emotion,
                                onSelected: () => setState(
                                  () => _selectedMoodFilter = emotion,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
                .animate()
                .slideY(
                  begin: 0.3,
                  delay: 200.ms,
                  duration: 500.ms,
                  curve: Curves.easeOut,
                )
                .fadeIn(delay: 200.ms),

            const SizedBox(height: AppConstants.paddingLarge),

            // Tab Bar View
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Diary Entries Tab
                  Consumer<DiaryProvider>(
                    builder: (context, diaryProvider, child) {
                      return StreamBuilder<List<DiaryEntry>>(
                        stream: diaryProvider.getDiaryEntriesStream(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(
                                color: AppTheme.primaryColor,
                              ),
                            );
                          }

                          if (snapshot.hasError) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.error_outline_rounded,
                                    size: 64,
                                    color: Colors.red.shade300,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Error loading diary entries',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          color: AppTheme.textSecondary,
                                        ),
                                  ),
                                ],
                              ),
                            );
                          }

                          List<DiaryEntry> entries = snapshot.data ?? [];

                          // Apply filters
                          if (_searchQuery.isNotEmpty) {
                            entries = entries
                                .where(
                                  (entry) =>
                                      entry.title.toLowerCase().contains(
                                        _searchQuery.toLowerCase(),
                                      ) ||
                                      entry.content.toLowerCase().contains(
                                        _searchQuery.toLowerCase(),
                                      ) ||
                                      entry.tags.any(
                                        (tag) => tag.toLowerCase().contains(
                                          _searchQuery.toLowerCase(),
                                        ),
                                      ),
                                )
                                .toList();
                          }

                          if (_selectedMoodFilter != 'all') {
                            entries = entries
                                .where(
                                  (entry) => entry.mood == _selectedMoodFilter,
                                )
                                .toList();
                          }

                          if (entries.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.book_outlined,
                                    size: 64,
                                    color: AppTheme.textTertiary,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _searchQuery.isNotEmpty ||
                                            _selectedMoodFilter != 'all'
                                        ? 'No diary entries found'
                                        : 'No diary entries yet',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          color: AppTheme.textSecondary,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _searchQuery.isNotEmpty ||
                                            _selectedMoodFilter != 'all'
                                        ? 'Try different search terms or filters'
                                        : 'Start writing your emotional journey',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: AppTheme.textTertiary,
                                        ),
                                  ),
                                ],
                              ),
                            );
                          }

                          return ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppConstants.paddingLarge,
                            ),
                            itemCount: entries.length,
                            itemBuilder: (context, index) {
                              final entry = entries[index];
                              return DiaryEntryCard(
                                    entry: entry,
                                    onEdit: () =>
                                        _showAddDiaryDialog(entry: entry),
                                    onDelete: () async {
                                      final shouldDelete =
                                          await _showDeleteConfirmation(
                                            context,
                                          );
                                      if (shouldDelete == true && mounted) {
                                        final success = await diaryProvider
                                            .deleteDiaryEntry(entry.id);
                                        if (success && mounted) {
                                          ToastUtils.showSuccessToast(
                                            message: 'Diary entry deleted',
                                            context: context,
                                          );
                                        }
                                      }
                                    },
                                  )
                                  .animate()
                                  .slideX(
                                    begin: 0.3,
                                    delay: Duration(milliseconds: index * 100),
                                    duration: 500.ms,
                                    curve: Curves.easeOut,
                                  )
                                  .fadeIn(
                                    delay: Duration(milliseconds: index * 100),
                                  );
                            },
                          );
                        },
                      );
                    },
                  ),
                  // Emotion Entries Tab
                  Consumer<EmotionProvider>(
                    builder: (context, emotionProvider, child) {
                      return StreamBuilder<List<EmotionEntry>>(
                        stream: emotionProvider.getEmotionEntriesStream(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(
                                color: AppTheme.primaryColor,
                              ),
                            );
                          }

                          if (snapshot.hasError) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.error_outline_rounded,
                                    size: 64,
                                    color: Colors.red.shade300,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Error loading emotion entries',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          color: AppTheme.textSecondary,
                                        ),
                                  ),
                                ],
                              ),
                            );
                          }

                          List<EmotionEntry> entries = snapshot.data ?? [];

                          // Apply filters
                          if (_searchQuery.isNotEmpty) {
                            entries = entries
                                .where(
                                  (entry) =>
                                      entry.emotion.toLowerCase().contains(
                                        _searchQuery.toLowerCase(),
                                      ) ||
                                      (entry.note?.toLowerCase().contains(
                                            _searchQuery.toLowerCase(),
                                          ) ??
                                          false),
                                )
                                .toList();
                          }

                          if (_selectedMoodFilter != 'all') {
                            entries = entries
                                .where(
                                  (entry) =>
                                      entry.emotion == _selectedMoodFilter,
                                )
                                .toList();
                          }

                          if (entries.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.mood,
                                    size: 64,
                                    color: AppTheme.textTertiary,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _searchQuery.isNotEmpty ||
                                            _selectedMoodFilter != 'all'
                                        ? 'No emotion entries found'
                                        : 'No emotion entries yet',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          color: AppTheme.textSecondary,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _searchQuery.isNotEmpty ||
                                            _selectedMoodFilter != 'all'
                                        ? 'Try different search terms or filters'
                                        : 'Capture your emotions to start',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: AppTheme.textTertiary,
                                        ),
                                  ),
                                ],
                              ),
                            );
                          }

                          return ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppConstants.paddingLarge,
                            ),
                            itemCount: entries.length,
                            itemBuilder: (context, index) {
                              final entry = entries[index];
                              return EmotionEntryCard(
                                    entry: entry,
                                    onEdit: () =>
                                        _showEditEmotionNoteDialog(entry),
                                    onDelete: () async {
                                      final shouldDelete =
                                          await _showDeleteConfirmation(
                                            context,
                                          );
                                      if (shouldDelete == true && mounted) {
                                        final success = await emotionProvider
                                            .deleteEmotionEntry(entry.id);
                                        if (success && mounted) {
                                          ToastUtils.showSuccessToast(
                                            message: 'Emotion entry deleted',
                                            context: context,
                                          );
                                        }
                                      }
                                    },
                                  )
                                  .animate()
                                  .slideX(
                                    begin: 0.3,
                                    delay: Duration(milliseconds: index * 100),
                                    duration: 500.ms,
                                    curve: Curves.easeOut,
                                  )
                                  .fadeIn(
                                    delay: Duration(milliseconds: index * 100),
                                  );
                            },
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _showDeleteConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Entry'),
        content: const Text(
          'Are you sure you want to delete this entry? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _MoodFilterChip extends StatelessWidget {
  final String label;
  final String emoji;
  final bool isSelected;
  final VoidCallback onSelected;

  const _MoodFilterChip({
    required this.label,
    required this.emoji,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
        selected: isSelected,
        onSelected: (_) => onSelected(),
        selectedColor: AppTheme.primaryColor,
        backgroundColor: Colors.white,
        side: BorderSide(
          color: isSelected ? AppTheme.primaryColor : Colors.grey.shade200,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}
