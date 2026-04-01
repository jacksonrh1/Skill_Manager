import 'task_item.dart';

class Skill {
  const Skill({
    required this.id,
    required this.title,
    required this.notes,
    required this.goals,
    required this.sortOrder,
  });

  final String id;
  final String title;
  final String notes;
  final List<GoalItem> goals;
  final int sortOrder;

  int get totalTrackableItems =>
      goals.fold<int>(0, (sum, goal) => sum + goal.totalTrackableItems);

  int get completedTrackableItems =>
      goals.fold<int>(0, (sum, goal) => sum + goal.completedTrackableItems);

  double get progress =>
      totalTrackableItems == 0 ? 0 : completedTrackableItems / totalTrackableItems;

  int get progressScore => (progress * 100).round();

  Skill copyWith({
    String? id,
    String? title,
    String? notes,
    List<GoalItem>? goals,
    int? sortOrder,
  }) {
    return Skill(
      id: id ?? this.id,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      goals: goals ?? this.goals,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'notes': notes,
      'goals': goals.map((goal) => goal.toJson()).toList(),
      'sortOrder': sortOrder,
    };
  }

  factory Skill.fromJson(Map<String, dynamic> json) {
    return Skill(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Skill',
      notes: json['notes'] as String? ?? '',
      goals: ((json['goals'] as List<dynamic>?) ?? [])
          .map((item) => GoalItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      sortOrder: json['sortOrder'] as int? ?? 0,
    );
  }

  factory Skill.create({
    required String id,
    required String title,
    String notes = '',
    List<GoalItem> goals = const [],
    int sortOrder = 0,
  }) {
    return Skill(
      id: id,
      title: title,
      notes: notes,
      goals: goals,
      sortOrder: sortOrder,
    );
  }
}
