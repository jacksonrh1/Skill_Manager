class ProfileData {
  const ProfileData({
    required this.name,
    required this.avatarIndex,
    required this.avatarImagePath,
  });

  final String name;
  final int avatarIndex;
  final String? avatarImagePath;

  ProfileData copyWith({
    String? name,
    int? avatarIndex,
    String? avatarImagePath,
    bool clearAvatarImagePath = false,
  }) {
    return ProfileData(
      name: name ?? this.name,
      avatarIndex: avatarIndex ?? this.avatarIndex,
      avatarImagePath: clearAvatarImagePath
          ? null
          : avatarImagePath ?? this.avatarImagePath,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'avatarIndex': avatarIndex,
      'avatarImagePath': avatarImagePath,
    };
  }

  factory ProfileData.fromJson(Map<String, dynamic> json) {
    return ProfileData(
      name: json['name'] as String? ?? 'John Doe',
      avatarIndex: json['avatarIndex'] as int? ?? 0,
      avatarImagePath: json['avatarImagePath'] as String?,
    );
  }
}
