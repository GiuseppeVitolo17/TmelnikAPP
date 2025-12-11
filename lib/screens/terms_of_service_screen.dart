import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGrey,
      appBar: AppBar(
        title: const Text('Terms of Service'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppShadows.soft,
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Terms of Service',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Last updated: ${DateTime.now().toString().split(' ')[0]}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              _buildSection(
                '1. Acceptance of Terms',
                'By accessing and using this application, you accept and agree to be bound by the terms and provision of this agreement.',
              ),
              _buildSection(
                '2. Use License',
                'Permission is granted to temporarily download and use the application for personal, non-commercial use only. This is the grant of a license, not a transfer of title.',
              ),
              _buildSection(
                '3. User Account',
                'You are responsible for:\n'
                '• Maintaining the confidentiality of your account\n'
                '• All activities that occur under your account\n'
                '• Ensuring the accuracy of information provided\n'
                '• Notifying us immediately of unauthorized use',
              ),
              _buildSection(
                '4. User Conduct',
                'You agree not to:\n'
                '• Use the service for any unlawful purpose\n'
                '• Post false, misleading, or fraudulent information\n'
                '• Interfere with or disrupt the service\n'
                '• Attempt to gain unauthorized access to any part of the service\n'
                '• Harass, abuse, or harm other users',
              ),
              _buildSection(
                '5. Project Applications',
                'When applying to projects:\n'
                '• You provide accurate and complete information\n'
                '• You understand that organizations review applications independently\n'
                '• We are not responsible for application outcomes\n'
                '• Application decisions are made solely by the organizations',
              ),
              _buildSection(
                '6. Content Ownership',
                'You retain ownership of content you submit. By submitting content, you grant us a license to:\n'
                '• Display and distribute your content through the service\n'
                '• Share your application information with relevant organizations',
              ),
              _buildSection(
                '7. Limitation of Liability',
                'We shall not be liable for any indirect, incidental, special, consequential, or punitive damages resulting from:\n'
                '• Your use or inability to use the service\n'
                '• Any errors or omissions in the content\n'
                '• Any loss or damage of any kind incurred as a result of using the service',
              ),
              _buildSection(
                '8. Indemnification',
                'You agree to indemnify and hold harmless the service providers from any claims, damages, losses, liabilities, and expenses arising from your use of the service or violation of these terms.',
              ),
              _buildSection(
                '9. Termination',
                'We reserve the right to terminate or suspend your account immediately, without prior notice, for any breach of these Terms of Service.',
              ),
              _buildSection(
                '10. Changes to Terms',
                'We reserve the right to modify these terms at any time. Your continued use of the service after changes constitutes acceptance of the new terms.',
              ),
              _buildSection(
                '11. Governing Law',
                'These terms shall be governed by and construed in accordance with applicable laws, without regard to conflict of law provisions.',
              ),
              _buildSection(
                '12. Contact Information',
                'For questions about these Terms of Service, please contact us at:\n'
                'Email: legal@tmelnikapp.com',
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.orange.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange[700],
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'By using this application, you acknowledge that you have read, understood, and agree to be bound by these Terms of Service.',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

