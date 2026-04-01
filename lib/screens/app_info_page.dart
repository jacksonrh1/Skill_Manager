import 'package:flutter/material.dart';

class AppInfoPage extends StatelessWidget {
  const AppInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Info'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: const [
          Text(
            'Welcome to Skill Manager!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 18),
          _InfoSection(
            title: 'Skill Dashboard',
            body:
                'This contains your skills you add using the add button in the top right of the screen. To move skills around the grid hold them down to unlock movement and drag to desired location. The skills give you a score out of 100 based on the amount of tasks completed vs the amount of task in the skill. The notes inside of skills save. Add goals, tasks, and subtasks using the add button in the bottom right. You can select where the tasks/subtasks go and drag them to the desired locations. The top right of the chosen skill screen shows the amount of total tasks. Change the skills name by clicking on it once the skill is selected.',
          ),
          _InfoSection(
            title: 'Profile',
            body:
                'The profile page shows your stats with a stat tracker and shows progress within your skills. Here you can input your name and profile picture. In the top right is settings.',
          ),
          _InfoSection(
            title: 'Settings',
            body:
                'Settings includes the dark mode/light mode switch, a email to send reccomendations, the app info, the terms and conditions, and signing out/deleting your account.',
          ),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              fontSize: 14,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}
