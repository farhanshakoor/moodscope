import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';

class AddDiaryDialog extends StatefulWidget {
  final Function(String title, String content, String mood, List<String> tags) onSave;

  const AddDiaryDialog({super.key, required this.onSave});

  @override
  State<AddDiaryDialog> createState() => _AddDiaryDialogState();
}

class _AddDiaryDialogState extends State<AddDiaryDialog> with SingleTickerProviderStateMixin {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _tagController = TextEditingController();
  String _selectedMood = 'neutral';
  List<String> _tags = [];
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);
    _animationController.forward();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  void _saveDiary() {
    if (_titleController.text.trim().isEmpty || _contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill in both title and content'), backgroundColor: Colors.red));
      return;
    }

    widget.onSave(_titleController.text.trim(), _contentController.text.trim(), _selectedMood, _tags);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _animationController.value,
            child: Opacity(
              opacity: _animationController.value,
              child: Container(
                constraints: const BoxConstraints(maxHeight: 600),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, spreadRadius: 5)],
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.paddingLarge),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header
                        Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(25)),
                              child: const Icon(Icons.book_rounded, color: Colors.white, size: 24),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('New Diary Entry', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text('Capture your emotional moment', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary)),
                                ],
                              ),
                            ),
                          ],
                        ).animate().slideX(begin: -0.5, duration: 400.ms, curve: Curves.easeOut).fadeIn(),

                        const SizedBox(height: 24),

                        // Title Field
                        Text('Title', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _titleController,
                          decoration: InputDecoration(
                            hintText: 'Give your entry a title...',
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade200),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade200),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
                            ),
                          ),
                        ).animate().slideY(begin: 0.3, delay: 200.ms, duration: 400.ms, curve: Curves.easeOut).fadeIn(delay: 200.ms),

                        const SizedBox(height: 20),

                        // Mood Selection
                        Text('How are you feeling?', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: AppConstants.emotionLabels.map((emotion) {
                            final isSelected = _selectedMood == emotion;
                            final emotionColor = AppTheme.emotionColors[emotion] ?? AppTheme.textTertiary;
                            final emotionEmoji = AppConstants.emotionEmojis[emotion] ?? '😐';

                            return GestureDetector(
                              onTap: () => setState(() => _selectedMood = emotion),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: isSelected ? emotionColor.withOpacity(0.2) : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: isSelected ? emotionColor : Colors.grey.shade300, width: isSelected ? 2 : 1),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(emotionEmoji, style: const TextStyle(fontSize: 16)),
                                    const SizedBox(width: 8),
                                    Text(
                                      emotion,
                                      style: TextStyle(fontWeight: FontWeight.w600, color: isSelected ? emotionColor : AppTheme.textPrimary),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 20),

                        // Content Field
                        Text('Your Story', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _contentController,
                          maxLines: 5,
                          decoration: InputDecoration(
                            hintText: 'Write your diary entry...',
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade200),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade200),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Tags Section
                        Text('Tags', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _tagController,
                                decoration: InputDecoration(
                                  hintText: 'Add a tag...',
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey.shade200),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: _addTag,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Add'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: _tags.map((tag) => Chip(label: Text(tag), onDeleted: () => _removeTag(tag), deleteIcon: const Icon(Icons.close, size: 16))).toList(),
                        ),

                        const SizedBox(height: 24),

                        // Action Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: _saveDiary,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Save'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
