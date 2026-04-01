import 'dart:math' as math;
import 'dart:io';

import 'package:flutter/material.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.name,
    required this.avatarIndex,
    this.avatarImagePath,
    this.radius = 24,
    this.showEditBadge = false,
  });

  final String name;
  final int avatarIndex;
  final String? avatarImagePath;
  final double radius;
  final bool showEditBadge;

  static const _palettes = <List<Color>>[
    [Color(0xFF6EA7FF), Color(0xFF9FD3FF)],
    [Color(0xFFFF9F7A), Color(0xFFFFD1A9)],
    [Color(0xFF70D7B8), Color(0xFFACF0D0)],
    [Color(0xFF9985FF), Color(0xFFD7D0FF)],
    [Color(0xFFFF7388), Color(0xFFFFC4CB)],
  ];

  static List<List<Color>> get palettes => _palettes;

  @override
  Widget build(BuildContext context) {
    final colors = _palettes[avatarIndex % _palettes.length];
    final initials = _initials(name);
    final imageProvider = _buildImageProvider();

    final avatar = Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: imageProvider == null
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: colors,
              )
            : null,
        image: imageProvider == null
            ? null
            : DecorationImage(
                image: imageProvider,
                fit: BoxFit.cover,
              ),
        boxShadow: [
          BoxShadow(
            color: colors.first.withValues(alpha: 0.28),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: imageProvider != null
          ? null
          : Transform.rotate(
              angle: -math.pi / 30,
              child: Text(
                initials,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: radius * 0.72,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                ),
              ),
            ),
    );

    return _buildWithBadge(avatar);
  }

  Widget _buildWithBadge(Widget avatar) {
    if (!showEditBadge) {
      return avatar;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        Positioned(
          right: -2,
          bottom: -2,
          child: Container(
            width: radius * 0.72,
            height: radius * 0.72,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.edit_rounded,
              size: 14,
              color: Color(0xFF5D9EF8),
            ),
          ),
        ),
      ],
    );
  }

  ImageProvider<Object>? _buildImageProvider() {
    final path = avatarImagePath;
    if (path == null || path.isEmpty) {
      return null;
    }

    final file = File(path);
    if (!file.existsSync()) {
      return null;
    }

    return FileImage(file);
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty);
    if (parts.isEmpty) {
      return 'U';
    }
    final chars = parts.take(2).map((part) => part[0].toUpperCase()).join();
    return chars;
  }
}
