import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:moodscope/features/auth/provider/auth_provider.dart';
import 'package:moodscope/features/auth/widgets/auth_text_field.dart';
import 'package:moodscope/features/dashboard/screens/home_screen.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please accept the terms and conditions'), backgroundColor: Colors.red));
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.signUpWithEmail(_emailController.text, _passwordController.text, _nameController.text);

    if (success && mounted) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.paddingLarge),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppConstants.paddingLarge),

                  // Back Button
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_ios_rounded),
                    style: IconButton.styleFrom(backgroundColor: Colors.white, padding: const EdgeInsets.all(12)),
                  ).animate().slideX(begin: -0.5, duration: 600.ms, curve: Curves.easeOutBack).fadeIn(),

                  const SizedBox(height: AppConstants.paddingLarge),

                  // Title
                  Text(
                    'Create\nAccount 🚀',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(fontWeight: FontWeight.bold, height: 1.2),
                  ).animate().slideX(begin: -0.5, delay: 100.ms, duration: 600.ms, curve: Curves.easeOutBack).fadeIn(delay: 100.ms),

                  const SizedBox(height: AppConstants.paddingMedium),

                  Text(
                    'Join MoodScope and start tracking your emotions',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary),
                  ).animate().slideX(begin: -0.5, delay: 200.ms, duration: 600.ms, curve: Curves.easeOutBack).fadeIn(delay: 200.ms),

                  const SizedBox(height: AppConstants.paddingExtraLarge),

                  // Signup Form
                  Consumer<AuthProvider>(
                    builder: (context, authProvider, child) {
                      return Column(
                        children: [
                          // Name Field
                          AuthTextField(
                            controller: _nameController,
                            label: 'Full Name',
                            hintText: 'Enter your full name',
                            prefixIcon: Icons.person_outline,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your name';
                              }
                              if (value.trim().length < 2) {
                                return 'Name must be at least 2 characters';
                              }
                              return null;
                            },
                          ).animate().slideX(begin: 0.5, delay: 300.ms, duration: 600.ms, curve: Curves.easeOutBack).fadeIn(delay: 300.ms),

                          const SizedBox(height: AppConstants.paddingMedium),

                          // Email Field
                          AuthTextField(
                            controller: _emailController,
                            label: 'Email',
                            hintText: 'Enter your email',
                            prefixIcon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ).animate().slideX(begin: 0.5, delay: 400.ms, duration: 600.ms, curve: Curves.easeOutBack).fadeIn(delay: 400.ms),

                          const SizedBox(height: AppConstants.paddingMedium),

                          // Password Field
                          AuthTextField(
                            controller: _passwordController,
                            label: 'Password',
                            hintText: 'Enter your password',
                            prefixIcon: Icons.lock_outline,
                            obscureText: _obscurePassword,
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ).animate().slideX(begin: 0.5, delay: 500.ms, duration: 600.ms, curve: Curves.easeOutBack).fadeIn(delay: 500.ms),

                          const SizedBox(height: AppConstants.paddingMedium),

                          // Confirm Password Field
                          AuthTextField(
                            controller: _confirmPasswordController,
                            label: 'Confirm Password',
                            hintText: 'Confirm your password',
                            prefixIcon: Icons.lock_outline,
                            obscureText: _obscureConfirmPassword,
                            suffixIcon: IconButton(
                              icon: Icon(_obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword = !_obscureConfirmPassword;
                                });
                              },
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please confirm your password';
                              }
                              if (value != _passwordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ).animate().slideX(begin: 0.5, delay: 600.ms, duration: 600.ms, curve: Curves.easeOutBack).fadeIn(delay: 600.ms),

                          const SizedBox(height: AppConstants.paddingMedium),

                          // Terms and Conditions
                          Row(
                            children: [
                              Checkbox(
                                value: _acceptTerms,
                                onChanged: (value) {
                                  setState(() {
                                    _acceptTerms = value ?? false;
                                  });
                                },
                                activeColor: AppTheme.primaryColor,
                              ),
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
                                    children: const [
                                      TextSpan(text: 'I agree to the '),
                                      TextSpan(
                                        text: 'Terms & Conditions',
                                        style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w600),
                                      ),
                                      TextSpan(text: ' and '),
                                      TextSpan(
                                        text: 'Privacy Policy',
                                        style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ).animate().slideX(begin: 0.5, delay: 700.ms, duration: 600.ms, curve: Curves.easeOutBack).fadeIn(delay: 700.ms),

                          const SizedBox(height: AppConstants.paddingLarge),

                          // Error Message
                          if (authProvider.errorMessage != null)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                border: Border.all(color: Colors.red.shade200),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(authProvider.errorMessage!, style: TextStyle(color: Colors.red.shade700, fontSize: 14)),
                            ).animate().slideY(begin: -0.5, duration: 300.ms, curve: Curves.easeOut).fadeIn(),

                          // Sign Up Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: authProvider.isLoading ? null : _signUp,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: authProvider.isLoading
                                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Text(
                                      'Create Account',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                                    ),
                            ),
                          ).animate().slideY(begin: 0.5, delay: 800.ms, duration: 600.ms, curve: Curves.easeOutBack).fadeIn(delay: 800.ms),

                          const SizedBox(height: AppConstants.paddingLarge),

                          // Divider
                          Row(
                            children: [
                              const Expanded(child: Divider()),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text('or', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textTertiary)),
                              ),
                              const Expanded(child: Divider()),
                            ],
                          ).animate().fadeIn(delay: 900.ms),

                          // Sign In Link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Already have an account? ', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary)),
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text(
                                  'Sign In',
                                  style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.primaryColor),
                                ),
                              ),
                            ],
                          ).animate().slideY(begin: 0.5, delay: 1100.ms, duration: 600.ms, curve: Curves.easeOutBack).fadeIn(delay: 1100.ms),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
