import 'package:flutter/material.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';

import '../state/app_scope.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/skill_card.dart';
import 'profile_page.dart';
import 'skill_detail_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final skills = store.skills;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? const Color(0xFFF5F7FB) : const Color(0xFF2A3243);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
          child: Column(
            children: [
              Row(
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(30),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ProfilePage(store: store),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        ProfileAvatar(
                          name: store.profile.name,
                          avatarIndex: store.profile.avatarIndex,
                          avatarImagePath: store.profile.avatarImagePath,
                          radius: 18,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'My Skills',
                          style: TextStyle(
                            color: titleColor,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  _TopActionButton(
                    icon: Icons.add_rounded,
                    onTap: () => _showAddSkillDialog(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ReorderableGridView.builder(
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: skills.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 0.95,
                  ),
                  dragEnabled: true,
                  onReorder: (oldIndex, newIndex) {
                    store.reorderSkills(
                      oldIndex: oldIndex,
                      newIndex: newIndex,
                    );
                  },
                  itemBuilder: (context, index) {
                    final skill = skills[index];
                    return Container(
                      key: ValueKey(skill.id),
                      child: SkillCard(
                        skill: skill,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => SkillDetailPage(
                                skillId: skill.id,
                                store: store,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAddSkillDialog(BuildContext context) async {
    final controller = TextEditingController();
    final store = AppScope.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1B2433) : Colors.white,
          title: Text(
            'Add Skill',
            style: TextStyle(
              color: isDark ? const Color(0xFFF5F7FB) : const Color(0xFF2A3243),
            ),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              hintText: 'Skill title',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                store.addSkill(controller.text);
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }
}

class _TopActionButton extends StatelessWidget {
  const _TopActionButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? const Color(0xFF1B2433) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.24)
                    : Colors.black.withValues(alpha: 0.05),
                blurRadius: isDark ? 18 : 12,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: const Color(0xFF69A6F8),
          ),
        ),
      ),
    );
  }
}
