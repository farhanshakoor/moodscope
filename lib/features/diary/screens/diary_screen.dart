import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:moodscope/features/diary/widgets/add_diary_dialog.dart';
import 'package:moodscope/features/diary/widgets/diary_entry_card.dart';
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

class _DiaryScreenState extends State<DiaryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedMoodFilter = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddDiaryDialog() {
    showDialog(
      context: context,
      builder: (context) => AddDiaryDialog(
        onSave: (title, content, mood, tags) async {
          final diaryProvider = context.read<DiaryProvider>();
          final success = await diaryProvider.addDiaryEntry(title: title, content: content, mood: mood, tags: tags);

          if (success && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Diary entry saved! ${AppConstants.emotionEmojis[mood] ?? ''}'),
                backgroundColor: AppTheme.primaryColor,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
          }
        },
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
                          style: Theme.of(context).textTheme.displaySmall?.copyWith(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text('Track your emotional journey', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary)),
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: AppTheme.primaryColor.withOpacity(0.3), blurRadius: 8, spreadRadius: 2)],
                    ),
                    child: IconButton(
                      onPressed: _showAddDiaryDialog,
                      icon: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
                      style: IconButton.styleFrom(backgroundColor: Colors.transparent, padding: const EdgeInsets.all(12)),
                    ),
                  ),
                ],
              ),
            ).animate().slideY(begin: -0.5, duration: 600.ms, curve: Curves.easeOut).fadeIn(),

            // Search and Filter Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLarge),
              child: Column(
                children: [
                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, spreadRadius: 2)],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search your diary...',
                        prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textSecondary),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        hintStyle: TextStyle(color: AppTheme.textTertiary, fontSize: 14),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Mood Filter
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _MoodFilterChip(label: 'All', emoji: '📖', isSelected: _selectedMoodFilter == 'all', onSelected: () => setState(() => _selectedMoodFilter = 'all')),
                        ...AppConstants.emotionLabels.map(
                          (emotion) => _MoodFilterChip(
                            label: emotion.toUpperCase(),
                            emoji: AppConstants.emotionEmojis[emotion] ?? '😐',
                            isSelected: _selectedMoodFilter == emotion,
                            onSelected: () => setState(() => _selectedMoodFilter = emotion),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().slideY(begin: 0.3, delay: 200.ms, duration: 500.ms, curve: Curves.easeOut).fadeIn(delay: 200.ms),

            const SizedBox(height: AppConstants.paddingLarge),

            // Diary Entries List
            Expanded(
              child: Consumer<DiaryProvider>(
                builder: (context, diaryProvider, child) {
                  return StreamBuilder<List<DiaryEntry>>(
                    stream: diaryProvider.getDiaryEntriesStream(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline_rounded, size: 64, color: Colors.red.shade300),
                              const SizedBox(height: 16),
                              Text('Error loading diary entries', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.textSecondary)),
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
                                  entry.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                                  entry.content.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                                  entry.tags.any((tag) => tag.toLowerCase().contains(_searchQuery.toLowerCase())),
                            )
                            .toList();
                      }

                      if (_selectedMoodFilter != 'all') {
                        entries = entries.where((entry) => entry.mood == _selectedMoodFilter).toList();
                      }

                      if (entries.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.book_outlined, size: 64, color: AppTheme.textTertiary),
                              const SizedBox(height: 16),
                              Text(
                                _searchQuery.isNotEmpty || _selectedMoodFilter != 'all' ? 'No entries found' : 'No diary entries yet',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.textSecondary),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _searchQuery.isNotEmpty || _selectedMoodFilter != 'all' ? 'Try different search terms or filters' : 'Start writing your emotional journey',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textTertiary),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLarge),
                        itemCount: entries.length,
                        itemBuilder: (context, index) {
                          final entry = entries[index];
                          return DiaryEntryCard(
                                entry: entry,
                                onEdit: () {},
                                onDelete: () async {
                                  final shouldDelete = await _showDeleteConfirmation(context);
                                  if (shouldDelete == true) {
                                    final success = await diaryProvider.deleteDiaryEntry(entry.id);
                                    if (success && mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(const SnackBar(content: Text('Diary entry deleted'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating));
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
                              .fadeIn(delay: Duration(milliseconds: index * 100));
                        },
                      );
                    },
                  );
                },
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
        content: const Text('Are you sure you want to delete this diary entry? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
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

  const _MoodFilterChip({required this.label, required this.emoji, required this.isSelected, required this.onSelected});

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
              style: TextStyle(color: isSelected ? Colors.white : AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ],
        ),
        selected: isSelected,
        onSelected: (_) => onSelected(),
        selectedColor: AppTheme.primaryColor,
        backgroundColor: Colors.white,
        side: BorderSide(color: isSelected ? AppTheme.primaryColor : Colors.grey.shade200),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}
