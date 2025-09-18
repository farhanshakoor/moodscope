import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class SocialLoginButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String icon;
  final String text;
  final bool isLoading;

  const SocialLoginButton({super.key, required this.onPressed, required this.icon, required this.text, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppTheme.textPrimary,
          side: BorderSide(color: Colors.grey.shade200),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: isLoading
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Google Icon (placeholder - replace with actual icon)
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
                    child: const Center(
                      child: Text(
                        'G',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    text,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppTheme.textPrimary),
                  ),
                ],
              ),
      ),
    );
  }
}
