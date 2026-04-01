import 'package:flutter/material.dart';

import '../models/skill.dart';

class SkillCard extends StatelessWidget {
  const SkillCard({
    super.key,
    required this.skill,
    required this.onTap,
  });

  final Skill skill;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1B2433) : Colors.white;
    final titleColor = isDark ? const Color(0xFFF5F7FB) : Colors.black;
    final scoreColor = isDark ? const Color(0xFFF5F7FB) : const Color(0xFF161C28);
    final subScoreColor = isDark ? const Color(0xFF9FAACA) : const Color(0xFF7C879B);
    final progressBackground = isDark ? const Color(0xFF2B3648) : const Color(0xFFE8EDF6);

    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.26)
                    : const Color(0xFF2A334A).withValues(alpha: 0.06),
                blurRadius: isDark ? 28 : 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                skill.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: titleColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  height: 1.05,
                ),
              ),
              Expanded(
                child: Center(
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '${skill.progressScore}',
                          style: TextStyle(
                            color: scoreColor,
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1.2,
                          ),
                        ),
                        TextSpan(
                          text: '/100',
                          style: TextStyle(
                            color: subScoreColor,
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  minHeight: 6,
                  value: skill.progress.clamp(0, 1),
                  backgroundColor: progressBackground,
                  valueColor: const AlwaysStoppedAnimation(Color(0xFF69A6F8)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
