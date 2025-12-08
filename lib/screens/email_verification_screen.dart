import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';

/// Screen that blocks access until email is verified
class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isResending = false;
  bool _isChecking = false;
  Timer? _checkTimer;
  bool _emailVerified = false;

  @override
  void initState() {
    super.initState();
    _checkEmailStatus();
    _startPeriodicCheck();
  }

  Future<void> _checkEmailStatus() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        await user.reload();
        final updatedUser = _auth.currentUser;
        if (updatedUser?.emailVerified == true) {
          setState(() {
            _emailVerified = true;
          });
        }
      } catch (e) {
        // Silent fail
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _startPeriodicCheck();
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    super.dispose();
  }

  /// Check email verification status periodically
  void _startPeriodicCheck() {
    _checkTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final user = _auth.currentUser;
      if (user != null) {
        try {
          await user.reload();
          final updatedUser = _auth.currentUser;
          if (updatedUser?.emailVerified == true) {
            timer.cancel();
            // Email verified - trigger rebuild by calling setState
            if (mounted) {
              setState(() {});
            }
          }
        } catch (e) {
          // Silent fail - continue checking
        }
      }
    });
  }

  Future<void> _resendVerificationEmail() async {
    final user = _auth.currentUser;
    if (user == null) return;

    setState(() {
      _isResending = true;
    });

    try {
      await user.sendEmailVerification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('📧 Verification email sent!'),
                SizedBox(height: 4),
                Text(
                  '⚠️ Check your spam folder if not in inbox',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending email: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  Future<void> _checkVerificationStatus() async {
    setState(() {
      _isChecking = true;
    });

    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.reload();
        final updatedUser = _auth.currentUser;
        if (updatedUser?.emailVerified == true) {
          if (mounted) {
            // Email verified - trigger rebuild
            setState(() {});
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Email not yet verified. Please check your email.'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error checking status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out? You will need to verify your email again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _auth.signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    // If email is verified, show success message briefly then let AuthWrapper handle navigation
    if (_emailVerified) {
      return Scaffold(
        backgroundColor: AppColors.backgroundGrey,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 64),
              const SizedBox(height: 16),
              const Text(
                'Email verified!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Redirecting to app...',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final user = _auth.currentUser;
    final email = user?.email ?? 'your email';

    return Scaffold(
      backgroundColor: AppColors.backgroundGrey,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              
              // Icon
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.email_outlined,
                  size: 64,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: 32),

              // Title
              const Text(
                'Verify Your Email',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Description
              Text(
                'We\'ve sent a verification email to:\n$email',
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              
              // Spam warning
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange, width: 1),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '⚠️ If you don\'t see the email, check your spam folder!',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.orange[900],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Instructions
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppShadows.soft,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'What to do:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInstructionStep(
                      number: '1',
                      text: 'Check your email inbox (and spam folder)',
                    ),
                    const SizedBox(height: 12),
                    _buildInstructionStep(
                      number: '2',
                      text: 'Click the verification link in the email',
                    ),
                    const SizedBox(height: 12),
                    _buildInstructionStep(
                      number: '3',
                      text: 'Come back here and tap "I\'ve verified"',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Action buttons
              ElevatedButton.icon(
                onPressed: _isChecking ? null : _checkVerificationStatus,
                icon: _isChecking
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_circle),
                label: Text(_isChecking ? 'Checking...' : 'I\'ve verified my email'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              OutlinedButton.icon(
                onPressed: _isResending ? null : _resendVerificationEmail,
                icon: _isResending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                label: Text(_isResending ? 'Sending...' : 'Resend verification email'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryBlue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              TextButton(
                onPressed: _signOut,
                child: const Text(
                  'Sign Out',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionStep({required String number, required String text}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.primaryBlue,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.textPrimary,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
