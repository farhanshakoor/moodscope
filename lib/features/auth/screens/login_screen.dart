import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:moodscope/features/auth/provider/auth_provider.dart';
import 'package:moodscope/features/auth/screens/signup_screen.dart';
import 'package:moodscope/features/auth/widgets/auth_text_field.dart';
import 'package:moodscope/features/dashboard/screens/home_screen.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.signInWithEmail(_emailController.text, _passwordController.text);

    if (success && mounted) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
    }
  }

  void _navigateToSignup() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SignupScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: double.infinity,

        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.paddingLarge),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppConstants.paddingExtraLarge),

                  // Welcome Back Text
                  Text(
                    'Welcome\nBack! 👋',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(fontWeight: FontWeight.bold, height: 1.2),
                  ).animate().slideX(begin: -0.5, duration: 600.ms, curve: Curves.easeOutBack).fadeIn(),

                  const SizedBox(height: AppConstants.paddingMedium),

                  Text(
                    'Sign in to continue your emotional journey',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary),
                  ).animate().slideX(begin: -0.5, delay: 100.ms, duration: 600.ms, curve: Curves.easeOutBack).fadeIn(delay: 100.ms),

                  const SizedBox(height: AppConstants.paddingExtraLarge * 2),

                  // Login Form
                  Consumer<AuthProvider>(
                    builder: (context, authProvider, child) {
                      return Column(
                        children: [
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
                          ).animate().slideX(begin: 0.5, delay: 200.ms, duration: 600.ms, curve: Curves.easeOutBack).fadeIn(delay: 200.ms),

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
                          ).animate().slideX(begin: 0.5, delay: 300.ms, duration: 600.ms, curve: Curves.easeOutBack).fadeIn(delay: 300.ms),

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

                          // Sign In Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: authProvider.isLoading ? null : _signIn,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: authProvider.isLoading
                                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Text(
                                      'Sign In',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                                    ),
                            ),
                          ).animate().slideY(begin: 0.5, delay: 400.ms, duration: 600.ms, curve: Curves.easeOutBack).fadeIn(delay: 400.ms),

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
                          ).animate().fadeIn(delay: 500.ms),

                          // Sign Up Link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Don\'t have an account? ', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary)),
                              TextButton(
                                onPressed: _navigateToSignup,
                                child: const Text(
                                  'Sign Up',
                                  style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.primaryColor),
                                ),
                              ),
                            ],
                          ).animate().slideY(begin: 0.5, delay: 700.ms, duration: 600.ms, curve: Curves.easeOutBack).fadeIn(delay: 700.ms),
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
