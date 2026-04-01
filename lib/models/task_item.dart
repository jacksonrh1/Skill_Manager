class GoalItem {
  const GoalItem({
    required this.id,
    required this.title,
    required this.isComplete,
    required this.isExpanded,
    required this.tasks,
  });

  final String id;
  final String title;
  final bool isComplete;
  final bool isExpanded;
  final List<TaskItem> tasks;

  int get totalTrackableItems =>
      1 + tasks.fold<int>(0, (sum, task) => sum + task.totalTrackableItems);

  int get completedTrackableItems =>
      (isComplete ? 1 : 0) +
      tasks.fold<int>(0, (sum, task) => sum + task.completedTrackableItems);

  GoalItem copyWith({
    String? id,
    String? title,
    bool? isComplete,
    bool? isExpanded,
    List<TaskItem>? tasks,
  }) {
    return GoalItem(
      id: id ?? this.id,
      title: title ?? this.title,
      isComplete: isComplete ?? this.isComplete,
      isExpanded: isExpanded ?? this.isExpanded,
      tasks: tasks ?? this.tasks,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'isComplete': isComplete,
      'isExpanded': isExpanded,
      'tasks': tasks.map((task) => task.toJson()).toList(),
    };
  }

  factory GoalItem.fromJson(Map<String, dynamic> json) {
    return GoalItem(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Goal',
      isComplete: json['isComplete'] as bool? ?? false,
      isExpanded: json['isExpanded'] as bool? ?? true,
      tasks: ((json['tasks'] as List<dynamic>?) ?? [])
          .map((item) => TaskItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  factory GoalItem.create({
    required String id,
    required String title,
    List<TaskItem> tasks = const [],
    bool isComplete = false,
    bool isExpanded = true,
  }) {
    return GoalItem(
      id: id,
      title: title,
      isComplete: isComplete,
      isExpanded: isExpanded,
      tasks: tasks,
    );
  }
}

class TaskItem {
  const TaskItem({
    required this.id,
    required this.title,
    required this.isComplete,
    required this.isExpanded,
    required this.subtasks,
  });

  final String id;
  final String title;
  final bool isComplete;
  final bool isExpanded;
  final List<SubtaskItem> subtasks;

  int get totalTrackableItems => 1 + subtasks.length;

  int get completedTrackableItems =>
      (isComplete ? 1 : 0) +
      subtasks.where((subtask) => subtask.isComplete).length;

  TaskItem copyWith({
    String? id,
    String? title,
    bool? isComplete,
    bool? isExpanded,
    List<SubtaskItem>? subtasks,
  }) {
    return TaskItem(
      id: id ?? this.id,
      title: title ?? this.title,
      isComplete: isComplete ?? this.isComplete,
      isExpanded: isExpanded ?? this.isExpanded,
      subtasks: subtasks ?? this.subtasks,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'isComplete': isComplete,
      'isExpanded': isExpanded,
      'subtasks': subtasks.map((subtask) => subtask.toJson()).toList(),
    };
  }

  factory TaskItem.fromJson(Map<String, dynamic> json) {
    return TaskItem(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Task',
      isComplete: json['isComplete'] as bool? ?? false,
      isExpanded: json['isExpanded'] as bool? ?? true,
      subtasks: ((json['subtasks'] as List<dynamic>?) ?? [])
          .map((item) => SubtaskItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  factory TaskItem.create({
    required String id,
    required String title,
    List<SubtaskItem> subtasks = const [],
    bool isComplete = false,
    bool isExpanded = true,
  }) {
    return TaskItem(
      id: id,
      title: title,
      isComplete: isComplete,
      isExpanded: isExpanded,
      subtasks: subtasks,
    );
  }
}

class SubtaskItem {
  const SubtaskItem({
    required this.id,
    required this.title,
    required this.isComplete,
  });

  final String id;
  final String title;
  final bool isComplete;

  SubtaskItem copyWith({
    String? id,
    String? title,
    bool? isComplete,
  }) {
    return SubtaskItem(
      id: id ?? this.id,
      title: title ?? this.title,
      isComplete: isComplete ?? this.isComplete,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'isComplete': isComplete,
    };
  }

  factory SubtaskItem.fromJson(Map<String, dynamic> json) {
    return SubtaskItem(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Subtask',
      isComplete: json['isComplete'] as bool? ?? false,
    );
  }

  factory SubtaskItem.create({
    required String id,
    required String title,
    bool isComplete = false,
  }) {
    return SubtaskItem(
      id: id,
      title: title,
      isComplete: isComplete,
    );
  }
}
