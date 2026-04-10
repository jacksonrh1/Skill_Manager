import 'package:flutter/material.dart';

import '../services/profile_image_service.dart';
import '../state/app_store.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/stats_radar_chart.dart';
import 'settings_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({
    super.key,
    required this.store,
  });

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final primaryText = isDark ? const Color(0xFFF5F7FB) : const Color(0xFF1F2635);
        final secondaryText = isDark ? const Color(0xFF9FAACA) : const Color(0xFF8792A8);
        final cardColor = isDark ? const Color(0xFF1B2433) : Colors.white;
        final shadowColor = isDark
            ? Colors.black.withValues(alpha: 0.26)
            : const Color(0xFF2A334A).withValues(alpha: 0.06);

        return Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => SettingsPage(store: store),
                            ),
                          );
                        },
                        icon: const Icon(Icons.settings_outlined),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _showAvatarPicker(context),
                    child: ProfileAvatar(
                      name: store.profile.name,
                      avatarIndex: store.profile.avatarIndex,
                      avatarImagePath: store.profile.avatarImagePath,
                      radius: 42,
                      showEditBadge: true,
                    ),
                  ),
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: () => _showNameEditor(context),
                    child: Column(
                      children: [
                        Text(
                          store.profile.name,
                          style: TextStyle(
                            color: primaryText,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Tap to edit profile',
                          style: TextStyle(
                            color: secondaryText,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  _ProfileSummaryCard(store: store),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: [
                        BoxShadow(
                          color: shadowColor,
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Skill Stats',
                          style: TextStyle(
                            color: primaryText,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        StatsRadarChart(skills: store.skills),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  ...store.skills.map(
                    (skill) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _StatRow(
                        title: skill.title,
                        progressScore: skill.progressScore,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showNameEditor(BuildContext context) async {
    final controller = TextEditingController(text: store.profile.name);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF1B2433) : Colors.white;
    final primaryText = isDark ? const Color(0xFFF5F7FB) : const Color(0xFF1F2635);
    final secondaryText = isDark ? const Color(0xFF9FAACA) : const Color(0xFF8792A8);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: surfaceColor,
          title: Text(
            'Edit Name',
            style: TextStyle(color: primaryText),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: TextStyle(color: primaryText),
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              hintText: 'Your name',
              hintStyle: TextStyle(color: secondaryText),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                store.updateProfileName(controller.text);
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAvatarPicker(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF1B2433) : Colors.white;
    final primaryText = isDark ? const Color(0xFFF5F7FB) : const Color(0xFF263041);
    final secondaryText = isDark ? const Color(0xFF9FAACA) : const Color(0xFF7C879B);

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: surfaceColor,
      showDragHandle: true,
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Profile Picture',
                style: TextStyle(
                  color: primaryText,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.upload_rounded,
                  color: Color(0xFF5D9EF8),
                ),
                title: Text(
                  'Upload photo',
                  style: TextStyle(color: primaryText),
                ),
                subtitle: Text(
                  'Automatically resized to a square avatar',
                  style: TextStyle(color: secondaryText),
                ),
                onTap: () async {
                  final imagePath =
                      await ProfileImageService.pickAndSaveResizedImage();
                  if (imagePath == null || !context.mounted) {
                    return;
                  }
                  await store.updateAvatarImagePath(imagePath);
                  if (sheetContext.mounted) {
                    Navigator.of(sheetContext).pop();
                  }
                },
              ),
              if (store.profile.avatarImagePath != null)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.delete_outline_rounded,
                    color: Color(0xFFE35D6A),
                  ),
                  title: Text(
                    'Remove photo',
                    style: TextStyle(color: primaryText),
                  ),
                  subtitle: Text(
                    'Go back to a generated profile avatar',
                    style: TextStyle(color: secondaryText),
                  ),
                  onTap: () async {
                    await store.clearAvatarImagePath();
                    if (sheetContext.mounted) {
                      Navigator.of(sheetContext).pop();
                    }
                  },
                ),
              const SizedBox(height: 8),
              Text(
                'Or choose a profile style',
                style: TextStyle(
                  color: secondaryText,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: List.generate(ProfileAvatar.palettes.length, (index) {
                  return GestureDetector(
                    onTap: () {
                      store.updateAvatarIndex(index);
                      Navigator.of(sheetContext).pop();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: store.profile.avatarIndex == index
                              ? const Color(0xFF69A6F8)
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: ProfileAvatar(
                        name: store.profile.name,
                        avatarIndex: index,
                        avatarImagePath: store.profile.avatarImagePath,
                        radius: 26,
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProfileSummaryCard extends StatelessWidget {
  const _ProfileSummaryCard({
    required this.store,
  });

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    final total = store.skills.fold<int>(
      0,
      (sum, skill) => sum + skill.totalTrackableItems,
    );
    final completed = store.skills.fold<int>(
      0,
      (sum, skill) => sum + skill.completedTrackableItems,
    );
    final average = store.skills.isEmpty
        ? 0
        : (store.skills
                    .fold<int>(0, (sum, skill) => sum + skill.progressScore) /
                store.skills.length)
            .round();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1B2433)
            : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withValues(alpha: 0.26)
                : const Color(0xFF2A334A).withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _SummaryMetric(
            label: 'Skills',
            value: '${store.skills.length}',
          ),
          _SummaryMetric(
            label: 'Done',
            value: '$completed/$total',
          ),
          _SummaryMetric(
            label: 'Average',
            value: '$average%',
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFFF5F7FB)
                : const Color(0xFF20293A),
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF9FAACA)
                : const Color(0xFF8792A8),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.title,
    required this.progressScore,
  });

  final String title;
  final int progressScore;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B2433) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.24)
                : const Color(0xFF2A334A).withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: isDark ? const Color(0xFFF5F7FB) : const Color(0xFF2A3243),
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '$progressScore/100',
            style: TextStyle(
              color: isDark ? const Color(0xFF9FAACA) : const Color(0xFF5C677D),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: progressScore / 100,
              backgroundColor:
                  isDark ? const Color(0xFF2B3648) : const Color(0xFFE9EDF5),
              valueColor: const AlwaysStoppedAnimation(Color(0xFFFF966B)),
            ),
          ),
        ],
      ),
    );
  }
}
