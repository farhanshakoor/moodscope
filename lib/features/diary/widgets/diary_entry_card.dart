import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../models/diary_entry.dart';

class DiaryEntryCard extends StatelessWidget {
  final DiaryEntry entry;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const DiaryEntryCard({super.key, required this.entry, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final emotionColor = AppTheme.emotionColors[entry.mood] ?? AppTheme.textTertiary;
    final emotionEmoji = AppConstants.emotionEmojis[entry.mood] ?? '😐';
    final formattedDate = DateFormat('MMM dd, yyyy • hh:mm a').format(entry.timestamp);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, spreadRadius: 3)],
        border: Border.all(color: emotionColor.withOpacity(0.2), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with mood indicator
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [emotionColor.withOpacity(0.1), emotionColor.withOpacity(0.05)]),
              ),
              child: Row(
                children: [
                  // Mood emoji
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: emotionColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: emotionColor.withOpacity(0.3), width: 2),
                    ),
                    child: Center(child: Text(emotionEmoji, style: const TextStyle(fontSize: 24))),
                  ),

                  const SizedBox(width: 16),

                  // Title and date
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.title,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formattedDate,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),

                  // Mood label
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: emotionColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: emotionColor.withOpacity(0.3), width: 1),
                    ),
                    child: Text(
                      entry.mood.toUpperCase(),
                      style: TextStyle(color: emotionColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.content,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.textPrimary, height: 1.5),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),

                  if (entry.tags.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: entry.tags
                          .map(
                            (tag) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2), width: 1),
                              ),
                              child: Text(
                                '#$tag',
                                style: TextStyle(color: AppTheme.primaryColor, fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),

            // Action buttons
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 18, color: AppTheme.primaryColor),
                    label: const Text(
                      'Edit',
                      style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w600),
                    ),
                    style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                  ),

                  const SizedBox(width: 8),

                  TextButton.icon(
                    onPressed: onDelete,
                    icon: Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red.shade400),
                    label: Text(
                      'Delete',
                      style: TextStyle(color: Colors.red.shade400, fontWeight: FontWeight.w600),
                    ),
                    style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
