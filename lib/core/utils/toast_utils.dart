import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

class ToastUtils {
  static DateTime? _lastToastTime;
  static const _minimumToastInterval = Duration(milliseconds: 500);

  static bool _canShowToast() {
    final now = DateTime.now();
    if (_lastToastTime == null ||
        now.difference(_lastToastTime!) >= _minimumToastInterval) {
      _lastToastTime = now;
      return true;
    }
    return false;
  }

  static void showSuccessToast({
    BuildContext? context,
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) => _showToast(
    context: context,
    message: message,
    duration: duration,
    icon: Icons.check_circle_rounded,
    primaryColor: const Color(0xFF10B981),
    iconBgColor: const Color(0xFFECFDF5),
    textColor: const Color(0xFF065F46),
    borderColor: const Color(0xFFBBF7D0),
  );

  static void showErrorToast({
    BuildContext? context,
    required String message,
    Duration duration = const Duration(seconds: 4),
  }) => _showToast(
    context: context,
    message: message,
    duration: duration,
    icon: Icons.error_rounded,
    primaryColor: const Color(0xFFEF4444),
    iconBgColor: const Color(0xFFFEF2F2),
    textColor: const Color(0xFF991B1B),
    borderColor: const Color(0xFFFECACA),
  );

  static void showWarningToast({
    BuildContext? context,
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) => _showToast(
    context: context,
    message: message,
    duration: duration,
    icon: Icons.warning_rounded,
    primaryColor: const Color(0xFFF59E0B),
    iconBgColor: const Color(0xFFFEF3C7),
    textColor: const Color(0xFF92400E),
    borderColor: const Color(0xFFFDE68A),
  );

  static void showInfoToast({
    BuildContext? context,
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) => _showToast(
    context: context,
    message: message,
    duration: duration,
    icon: Icons.info_rounded,
    primaryColor: const Color(0xFF3B82F6),
    iconBgColor: const Color(0xFFEFF6FF),
    textColor: const Color(0xFF1E40AF),
    borderColor: const Color(0xFFBFDBFE),
  );

  static void showLoadingToast({
    BuildContext? context,
    required String message,
    Duration duration = const Duration(seconds: 2),
  }) {
    if (!_canShowToast()) return;

    toastification.showCustom(
      context: context,
      autoCloseDuration: duration,
      alignment: Alignment.topCenter,
      animationDuration: const Duration(milliseconds: 400),
      builder: (ctx, toastItem) => _buildLoadingToast(ctx, message, toastItem),
    );
  }

  static void _showToast({
    required BuildContext? context,
    required String message,
    required Duration duration,
    required IconData icon,
    required Color primaryColor,
    required Color iconBgColor,
    required Color textColor,
    required Color borderColor,
  }) {
    if (!_canShowToast()) return;

    toastification.showCustom(
      context: context,
      autoCloseDuration: duration,
      alignment: Alignment.bottomCenter,
      animationDuration: const Duration(milliseconds: 400),
      builder: (ctx, toastItem) => _buildModernToast(
        context: ctx,
        message: message,
        icon: icon,
        primaryColor: primaryColor,
        backgroundColor: Colors.white,
        iconBackgroundColor: iconBgColor,
        textColor: textColor,
        borderColor: borderColor,
        toastItem: toastItem,
      ),
    );
  }

  static Widget _buildModernToast({
    required BuildContext context,
    required String message,
    required IconData icon,
    required Color primaryColor,
    required Color backgroundColor,
    required Color iconBackgroundColor,
    required Color textColor,
    required Color borderColor,
    required ToastificationItem toastItem,
  }) {
    return _baseToastContainer(
      context: context,
      toastItem: toastItem,
      backgroundColor: backgroundColor,
      borderColor: borderColor,
      child: Row(
        children: [
          _iconCircle(icon, primaryColor, iconBackgroundColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          _closeButton(toastItem),
        ],
      ),
    );
  }

  static Widget _buildLoadingToast(
    BuildContext context,
    String message,
    ToastificationItem toastItem,
  ) {
    return _baseToastContainer(
      context: context,
      toastItem: toastItem,
      backgroundColor: Colors.white,
      borderColor: const Color(0xFFE5E7EB),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF6B7280).withAlpha((0.2 * 255).toInt()),
                width: 1,
              ),
            ),
            child: const Padding(
              padding: EdgeInsets.all(10),
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6B7280)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF374151),
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // Reusable toast container
  static Widget _baseToastContainer({
    required BuildContext context,
    required ToastificationItem toastItem,
    required Widget child,
    required Color backgroundColor,
    required Color borderColor,
  }) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.9,
        minHeight: 60,
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.08 * 255).toInt()),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => toastification.dismiss(toastItem),
          child: Padding(padding: const EdgeInsets.all(16), child: child),
        ),
      ),
    );
  }

  static Widget _iconCircle(IconData icon, Color primaryColor, Color bgColor) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: primaryColor.withAlpha((0.2 * 255).toInt()),
          width: 1,
        ),
      ),
      child: Icon(icon, color: primaryColor, size: 24),
    );
  }

  static Widget _closeButton(ToastificationItem toastItem) {
    return GestureDetector(
      onTap: () => toastification.dismiss(toastItem),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.grey.withAlpha((0.1 * 255).toInt()),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.close_rounded, color: Colors.grey[600], size: 18),
      ),
    );
  }

  static void dismissAll() => toastification.dismissAll();

  static void dismiss(ToastificationItem toastItem) =>
      toastification.dismiss(toastItem);
}
