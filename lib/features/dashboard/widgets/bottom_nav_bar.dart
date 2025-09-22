import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Colors.white.withOpacity(0.95)],
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: Container(
          height: 80,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Flexible(
                child: _NavBarItem(
                  icon: Icons.home_rounded,
                  label: 'Home',
                  isSelected: currentIndex == 0,
                  onTap: () => onTap(0),
                ),
              ),
              Flexible(
                child: _NavBarItem(
                  icon: Icons.camera_alt_rounded,
                  label: 'Detect',
                  isSelected: currentIndex == 1,
                  onTap: () => onTap(1),
                ),
              ),
              Flexible(
                child: _NavBarItem(
                  icon: Icons.book_rounded,
                  label: 'Diary',
                  isSelected: currentIndex == 2,
                  onTap: () => onTap(2),
                ),
              ),
              Flexible(
                child: _NavBarItem(
                  icon: Icons.analytics_rounded,
                  label: 'Analytics',
                  isSelected: currentIndex == 3,
                  onTap: () => onTap(3),
                ),
              ),
              Flexible(
                child: _NavBarItem(
                  icon: Icons.music_note_rounded,
                  label: 'Music',
                  isSelected: currentIndex == 4,
                  onTap: () => onTap(4),
                ),
              ),
              Flexible(
                child: _NavBarItem(
                  icon: Icons.person_rounded, // Corrected icon for Profile
                  label: 'Profile',
                  isSelected: currentIndex == 5,
                  onTap: () => onTap(5),
                ),
              ),
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

  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    print('Building _NavBarItem: $label, isSelected: $isSelected');

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppConstants.shortAnimationDuration,
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 10 : 6, // Further reduced padding
          vertical: 6, // Reduced vertical padding
        ),
        decoration: BoxDecoration(
          gradient: isSelected ? AppTheme.primaryGradient : null,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : const Color(0xFF1E293B),
              size: isSelected ? 20 : 18, // Smaller icons
            ),
            const SizedBox(height: 2), // Reduced spacing
            Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF1E293B),
                    fontSize: 8, // Smaller font size
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                )
                .animate()
                .slideY(
                  begin: 0.5,
                  duration: AppConstants.shortAnimationDuration,
                  curve: Curves.easeOut,
                )
                .fadeIn(),
          ],
        ),
      ),
    );
  }
}
