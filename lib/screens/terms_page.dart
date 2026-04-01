import 'package:flutter/material.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms and Conditions'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: const [
          _TermsSection(
            title: 'Effective Date',
            body:
                'These Terms and Conditions are effective as of March 29, 2026, and apply to your use of Skill Manager.',
          ),
          _TermsSection(
            title: 'Using Skill Manager',
            body:
                'Skill Manager is provided to help you create, track, and organize personal skills, goals, tasks, subtasks, and notes. You agree to use the app only for lawful purposes and in a way that does not interfere with the app or other users.',
          ),
          _TermsSection(
            title: 'Account Responsibility',
            body:
                'You are responsible for maintaining the accuracy of your account information and for activities that occur under your account. You should keep your sign-in credentials secure.',
          ),
          _TermsSection(
            title: 'Your Content',
            body:
                'You retain ownership of the notes, profile details, skill entries, and progress information you add to Skill Manager. By using the app, you grant permission for that data to be stored and processed so the app can function as intended.',
          ),
          _TermsSection(
            title: 'Acceptable Use',
            body:
                'You agree not to misuse the service, attempt unauthorized access, upload harmful content, or use the app in a way that could damage the service or violate applicable law.',
          ),
          _TermsSection(
            title: 'Availability',
            body:
                'Skill Manager is provided on an as-is and as-available basis. Features may change, improve, or be removed over time. Continuous availability is not guaranteed.',
          ),
          _TermsSection(
            title: 'Limitation of Liability',
            body:
                'To the fullest extent allowed by law, Skill Manager and its owner are not liable for indirect, incidental, special, consequential, or punitive damages, or for loss of data, progress, or productivity resulting from use of the app.',
          ),
          _TermsSection(
            title: 'Termination',
            body:
                'You may stop using Skill Manager at any time. Your account may be suspended or removed if you violate these terms or misuse the service. If you delete your account, your app data may be permanently removed.',
          ),
          _TermsSection(
            title: 'Changes to These Terms',
            body:
                'These Terms and Conditions may be updated from time to time. Continued use of Skill Manager after updates means you accept the revised terms.',
          ),
          _TermsSection(
            title: 'Contact',
            body:
                'For questions, feedback, or recommendations about Skill Manager, contact: Jrhbusinesss@gmail.com',
          ),
        ],
      ),
    );
  }
}

class _TermsSection extends StatelessWidget {
  const _TermsSection({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              height: 1.5,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
