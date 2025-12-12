import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGrey,
      appBar: AppBar(
        title: const Text('Privacy Policy'),
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
                'Privacy Policy',
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
                '1. Information We Collect',
                'We collect information you provide directly to us, including:\n'
                '• Email address and authentication credentials\n'
                '• Profile information (name, profile picture)\n'
                '• Application data for projects\n'
                '• Journal entries and daily reflections\n'
                '• Feedback and other user-generated content',
              ),
              _buildSection(
                '2. How We Use Your Information',
                'We use the information we collect to:\n'
                '• Provide and improve our services\n'
                '• Process and manage project applications\n'
                '• Send you notifications about projects and updates\n'
                '• Communicate with you about your account\n'
                '• Analyze usage patterns to improve user experience',
              ),
              _buildSection(
                '3. Data Storage and Security',
                'Your data is stored securely using Firebase services:\n'
                '• All data is encrypted in transit and at rest\n'
                '• We use industry-standard security measures\n'
                '• Access to your data is restricted to authorized personnel\n'
                '• Regular security audits and updates are performed',
              ),
              _buildSection(
                '4. Data Sharing',
                'We do not sell or rent your personal information. We may share your data only:\n'
                '• With organizations you apply to (with your consent)\n'
                '• To comply with legal obligations\n'
                '• To protect our rights and prevent fraud',
              ),
              _buildSection(
                '5. Your Rights',
                'You have the right to:\n'
                '• Access your personal data\n'
                '• Request correction of inaccurate data\n'
                '• Request deletion of your data\n'
                '• Export your data\n'
                '• Withdraw consent at any time',
              ),
              _buildSection(
                '6. Cookies and Tracking',
                'We use cookies and similar technologies to:\n'
                '• Maintain your session\n'
                '• Analyze app usage\n'
                '• Improve performance\n\n'
                'You can control cookies through your device settings.',
              ),
              _buildSection(
                '7. Children\'s Privacy',
                'Our services are not intended for users under 16 years of age. '
                'We do not knowingly collect personal information from children.',
              ),
              _buildSection(
                '8. Changes to This Policy',
                'We may update this Privacy Policy from time to time. '
                'We will notify you of any changes by posting the new policy on this page.',
              ),
              _buildSection(
                '9. Contact Us',
                'If you have questions about this Privacy Policy, please contact us through the app settings.',
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primaryBlue.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.primaryBlue,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'This privacy policy is compliant with GDPR and other applicable data protection regulations.',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textPrimary,
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

