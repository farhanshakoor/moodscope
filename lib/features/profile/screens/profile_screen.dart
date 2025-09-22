import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:moodscope/core/theme/app_theme.dart';
import 'package:moodscope/core/constants/app_constants.dart';
import 'package:moodscope/core/utils/toast_utils.dart';
import 'package:moodscope/features/auth/provider/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final authProvider = context.read<AuthProvider>();
    _nameController.text = authProvider.user?.displayName ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;
        final userName = user?.displayName ?? 'User';
        final userEmail = user?.email ?? 'No email';

        return Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.backgroundGradient,
          ),
          child: SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(AppConstants.paddingLarge),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Header
                      Text(
                            'Your Profile',
                            style: Theme.of(context).textTheme.displaySmall
                                ?.copyWith(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                          )
                          .animate()
                          .slideY(
                            begin: -0.5,
                            duration: 600.ms,
                            curve: Curves.easeOut,
                          )
                          .fadeIn(),
                      const SizedBox(height: 4),
                      Text(
                            'Manage your account details',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(color: AppTheme.textSecondary),
                          )
                          .animate()
                          .slideY(
                            begin: -0.5,
                            delay: 100.ms,
                            duration: 600.ms,
                            curve: Curves.easeOut,
                          )
                          .fadeIn(delay: 100.ms),
                      const SizedBox(height: AppConstants.paddingExtraLarge),

                      // Profile Picture
                      Center(
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                gradient: AppTheme.primaryGradient,
                                borderRadius: BorderRadius.circular(25),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryColor.withAlpha(
                                      (0.3 * 255).toInt(),
                                    ),
                                    blurRadius: 12,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: user?.photoURL != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(25),
                                      child: Image.network(
                                        user!.photoURL!,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : Center(
                                      child: Text(
                                        userName.substring(0, 1).toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                            ),
                          )
                          .animate()
                          .scale(
                            delay: 200.ms,
                            duration: 500.ms,
                            curve: Curves.easeOut,
                          )
                          .fadeIn(delay: 200.ms),
                      const SizedBox(height: AppConstants.paddingLarge),

                      // Profile Form
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                                  controller: _nameController,
                                  decoration: InputDecoration(
                                    labelText: 'Name',
                                    labelStyle: TextStyle(
                                      color: AppTheme.textSecondary,
                                    ),
                                    filled: true,
                                    fillColor: Colors.white.withOpacity(0.9),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Please enter your name';
                                    }
                                    return null;
                                  },
                                )
                                .animate()
                                .slideX(
                                  begin: -0.5,
                                  delay: 300.ms,
                                  duration: 500.ms,
                                )
                                .fadeIn(delay: 300.ms),
                            const SizedBox(height: AppConstants.paddingMedium),
                            TextFormField(
                                  initialValue: userEmail,
                                  decoration: InputDecoration(
                                    labelText: 'Email',
                                    labelStyle: TextStyle(
                                      color: AppTheme.textSecondary,
                                    ),
                                    filled: true,
                                    fillColor: Colors.white.withOpacity(0.9),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                  enabled: false,
                                )
                                .animate()
                                .slideX(
                                  begin: -0.5,
                                  delay: 400.ms,
                                  duration: 500.ms,
                                )
                                .fadeIn(delay: 400.ms),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppConstants.paddingExtraLarge),

                      // Update Profile Button
                      ElevatedButton(
                            onPressed: authProvider.isLoading
                                ? null
                                : () async {
                                    if (_formKey.currentState!.validate()) {
                                      final name = _nameController.text.trim();
                                      try {
                                        authProvider.setLoading(true);
                                        await user!.updateDisplayName(name);
                                        await FirebaseFirestore.instance
                                            .collection(
                                              AppConstants.usersCollection,
                                            )
                                            .doc(user.uid)
                                            .update({'name': name});
                                        ToastUtils.showSuccessToast(
                                          message:
                                              'Profile updated successfully',
                                        );
                                      } catch (e) {
                                        ToastUtils.showErrorToast(
                                          message:
                                              'Failed to update profile: $e',
                                        );
                                      } finally {
                                        authProvider.setLoading(false);
                                      }
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppConstants.paddingLarge,
                                vertical: AppConstants.paddingMedium,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: authProvider.isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Update Profile',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          )
                          .animate()
                          .slideY(
                            begin: 0.3,
                            delay: 500.ms,
                            duration: 500.ms,
                            curve: Curves.easeOut,
                          )
                          .fadeIn(delay: 500.ms),

                      const SizedBox(height: AppConstants.paddingLarge),

                      // Sign Out Button
                      OutlinedButton(
                            onPressed: authProvider.isLoading
                                ? null
                                : () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        backgroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        title: const Text('Sign Out'),
                                        content: const Text(
                                          'Are you sure you want to sign out?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            child: const Text(
                                              'Cancel',
                                              style: TextStyle(
                                                color: AppTheme.textSecondary,
                                              ),
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            child: const Text(
                                              'Sign Out',
                                              style: TextStyle(
                                                color: Colors.red,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      await authProvider.signOut();
                                      if (!authProvider.isAuthenticated) {
                                        Navigator.pushReplacementNamed(
                                          context,
                                          '/login',
                                        );
                                      }
                                    }
                                  },
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.red.shade300),
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppConstants.paddingLarge,
                                vertical: AppConstants.paddingMedium,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Sign Out',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.red,
                              ),
                            ),
                          )
                          .animate()
                          .slideY(
                            begin: 0.3,
                            delay: 600.ms,
                            duration: 500.ms,
                            curve: Curves.easeOut,
                          )
                          .fadeIn(delay: 600.ms),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
