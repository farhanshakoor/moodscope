import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavBar({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Colors.white, Colors.white.withOpacity(0.95)]),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, spreadRadius: 5)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: Container(
          height: 80,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _NavBarItem(icon: Icons.home_rounded, label: 'Home', isSelected: currentIndex == 0, onTap: () => onTap(0)),
              _NavBarItem(icon: Icons.camera_alt_rounded, label: 'Detect', isSelected: currentIndex == 1, onTap: () => onTap(1)),
              _NavBarItem(icon: Icons.book_rounded, label: 'Diary', isSelected: currentIndex == 2, onTap: () => onTap(2)),
              _NavBarItem(icon: Icons.analytics_rounded, label: 'Analytics', isSelected: currentIndex == 3, onTap: () => onTap(3)),
              _NavBarItem(icon: Icons.music_note_rounded, label: 'Music', isSelected: currentIndex == 4, onTap: () => onTap(4)),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavBarItem({required this.icon, required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Debug log to confirm widget is building
    print('Building _NavBarItem: $label, isSelected: $isSelected');

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppConstants.shortAnimationDuration,
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(horizontal: isSelected ? 16 : 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected ? AppTheme.primaryGradient : null,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected ? [BoxShadow(color: AppTheme.primaryColor.withOpacity(0.3), blurRadius: 8, spreadRadius: 1)] : null,
          // Removed color for non-selected items to avoid blending
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : const Color(0xFF1E293B), // Darker slate for non-selected icons
              size: isSelected ? 26 : 24, // Slightly larger icons
            ), // Simplified by removing animation for debugging
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF1E293B), // Match label color to icon
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ).animate().slideY(begin: 0.5, duration: AppConstants.shortAnimationDuration, curve: Curves.easeOut).fadeIn(),
          ],
        ),
      ),
    );
  }
}
