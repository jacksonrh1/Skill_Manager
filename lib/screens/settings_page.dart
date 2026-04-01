import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../state/app_store.dart';
import 'app_info_page.dart';
import 'terms_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({
    super.key,
    required this.store,
  });

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Settings'),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
            children: [
              _SectionCard(
                child: SwitchListTile(
                  value: store.isDarkMode,
                  onChanged: store.updateThemeMode,
                  title: const Text('Dark Theme'),
                  subtitle: const Text(
                    'Switch between the light and dark app themes.',
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _ActionCard(
                title: 'App Info',
                subtitle: 'Read how Skill Manager works and where everything is.',
                icon: Icons.info_outline_rounded,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const AppInfoPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 14),
              _ActionCard(
                title: 'Recommendations',
                subtitle: 'Send any app reccomendations here: Jrhbusinesss@gmail.com',
                icon: Icons.mail_outline_rounded,
                onTap: () => _showRecommendations(context),
              ),
              const SizedBox(height: 14),
              _ActionCard(
                title: 'Terms and Conditions',
                subtitle: 'Read the terms for using Skill Manager.',
                icon: Icons.description_outlined,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const TermsPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              FilledButton.tonal(
                onPressed: () async {
                  await store.signOut();
                },
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Sign Out'),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => _confirmDeleteAccount(context),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFDD4D5B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Delete Account'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showRecommendations(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Recommendations'),
          content: const Text(
            'Send any app reccomendations here: Jrhbusinesss@gmail.com',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final firstConfirm = await _showDecisionDialog(
      context: context,
      title: 'Delete account?',
      message: 'This will remove your profile and all saved skills from this app.',
      confirmLabel: 'Delete',
    );
    if (firstConfirm != true || !context.mounted) {
      return;
    }

    final secondConfirm = await _showDecisionDialog(
      context: context,
      title: 'Confirm delete',
      message: 'You will need to create a new account if you want to use the app again.',
      confirmLabel: 'Continue',
    );
    if (secondConfirm != true || !context.mounted) {
      return;
    }

    final finalConfirm = await _showDecisionDialog(
      context: context,
      title: 'Are you sure?',
      message: 'This final step permanently deletes your account. Choose Yes to continue.',
      confirmLabel: 'Yes',
      cancelLabel: 'No',
      destructive: true,
    );
    if (finalConfirm != true || !context.mounted) {
      return;
    }

    try {
      await store.deleteAccount();
    } on FirebaseAuthException catch (error) {
      if (!context.mounted) {
        return;
      }
      final message = error.code == 'requires-recent-login'
          ? 'Please sign in again before deleting your account.'
          : error.message ?? 'Unable to delete the account right now.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to delete the account right now.'),
        ),
      );
    }
  }

  Future<bool?> _showDecisionDialog({
    required BuildContext context,
    required String title,
    required String message,
    required String confirmLabel,
    String cancelLabel = 'Cancel',
    bool destructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(cancelLabel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: destructive
                  ? FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFDD4D5B),
                      foregroundColor: Colors.white,
                    )
                  : null,
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}
