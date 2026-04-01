import 'dart:async';

import 'package:flutter/material.dart';

import '../models/task_item.dart';
import '../state/app_store.dart';

class SkillDetailPage extends StatefulWidget {
  const SkillDetailPage({
    super.key,
    required this.skillId,
    required this.store,
  });

  final String skillId;
  final AppStore store;

  @override
  State<SkillDetailPage> createState() => _SkillDetailPageState();
}

class _SkillDetailPageState extends State<SkillDetailPage> {
  late final TextEditingController _notesController = TextEditingController();
  bool _notesInitialized = false;
  Timer? _notesSaveDebounce;

  @override
  void dispose() {
    _notesSaveDebounce?.cancel();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;

    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final skill = store.skillById(widget.skillId);
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final primaryText = isDark ? const Color(0xFFF5F7FB) : const Color(0xFF2A3243);
        final secondaryText = isDark ? const Color(0xFF9FAACA) : const Color(0xFF7C879B);
        final badgeColor = isDark ? const Color(0xFF1B2433) : Colors.white;

        if (!_notesInitialized) {
          _notesController.text = skill.notes;
          _notesController.addListener(() {
            _notesSaveDebounce?.cancel();
            _notesSaveDebounce = Timer(
              const Duration(milliseconds: 500),
              () {
                store.updateSkillNotes(widget.skillId, _notesController.text);
              },
            );
          });
          _notesInitialized = true;
        } else if (_notesController.text != skill.notes) {
          _notesController.value = TextEditingValue(
            text: skill.notes,
            selection: TextSelection.collapsed(offset: skill.notes.length),
          );
        }

        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            toolbarHeight: 74,
            titleSpacing: 8,
            title: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                ),
                const SizedBox(width: 2),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _showSkillTitleDialog(context, skill.title),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        skill.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: primaryText,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                onPressed: () => _confirmDeleteSkill(context, skill.title),
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFE35D6A),
                ),
                tooltip: 'Delete skill',
              ),
              Padding(
                padding: const EdgeInsets.only(right: 18, left: 4),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      '${skill.totalTrackableItems}',
                      style: TextStyle(
                        color: secondaryText,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: const Color(0xFF5D9EF8),
            foregroundColor: Colors.white,
            onPressed: () => _showAddItemSheet(context),
            child: const Icon(Icons.add, size: 34),
          ),
          body: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 110),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionCard(
                    title: 'Notes:',
                    child: TextField(
                      controller: _notesController,
                      minLines: 3,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        hintText: 'Write anything about this skill...',
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'Tasks:',
                    style: TextStyle(
                      color: primaryText,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ReorderableListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    buildDefaultDragHandles: false,
                    itemCount: skill.goals.length,
                    onReorder: (oldIndex, newIndex) {
                      store.reorderGoals(
                        skillId: skill.id,
                        oldIndex: oldIndex,
                        newIndex: newIndex,
                      );
                    },
                    itemBuilder: (context, index) {
                      final goal = skill.goals[index];
                      return Padding(
                        key: ValueKey(goal.id),
                        padding: const EdgeInsets.only(bottom: 16),
                      child: _GoalCard(
                        store: store,
                        skillId: skill.id,
                        goalIndex: index,
                        goal: goal,
                        onEdit: () {
                          _showGoalEditOptions(
                            context: context,
                            goal: goal,
                          );
                        },
                        onEditTask: (task) {
                          _showTaskEditOptions(
                            context: context,
                            task: task,
                            currentGoal: goal,
                            skillTitle: skill.title,
                          );
                        },
                        onEditSubtask: (task, subtask) {
                          _showSubtaskEditOptions(
                            context: context,
                            goal: goal,
                            task: task,
                            subtask: subtask,
                          );
                        },
                      ),
                      );
                    },
                  ),
                ],
              ),
          ),
        );
      },
    );
  }

  Future<void> _showAddItemSheet(BuildContext context) async {
    final store = widget.store;
    final skill = store.skillById(widget.skillId);
    final controller = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    var selectedType = _AddItemType.goal;
    String? selectedGoalId = skill.goals.isNotEmpty ? skill.goals.first.id : null;
    String? selectedTaskId = skill.goals.isNotEmpty && skill.goals.first.tasks.isNotEmpty
        ? skill.goals.first.tasks.first.id
        : null;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1B2433) : Colors.white,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final selectedGoal = skill.goals.where((goal) => goal.id == selectedGoalId);
            final tasks = selectedGoal.isEmpty ? <TaskItem>[] : selectedGoal.first.tasks;

            if (tasks.isNotEmpty &&
                (selectedTaskId == null || tasks.every((task) => task.id != selectedTaskId))) {
              selectedTaskId = tasks.first.id;
            }
            if (tasks.isEmpty) {
              selectedTaskId = null;
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(
                18,
                8,
                18,
                MediaQuery.of(sheetContext).viewInsets.bottom + 28,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add Progress Item',
                    style: TextStyle(
                      color: isDark ? const Color(0xFFF5F7FB) : const Color(0xFF263041),
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SegmentedButton<_AddItemType>(
                    segments: const [
                      ButtonSegment(
                        value: _AddItemType.goal,
                        label: Text('Goal'),
                      ),
                      ButtonSegment(
                        value: _AddItemType.task,
                        label: Text('Task'),
                      ),
                      ButtonSegment(
                        value: _AddItemType.subtask,
                        label: Text('Subtask'),
                      ),
                    ],
                    selected: {selectedType},
                    onSelectionChanged: (value) {
                      setSheetState(() {
                        selectedType = value.first;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    textCapitalization: TextCapitalization.sentences,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Enter ${selectedType.label.toLowerCase()} name',
                    ),
                  ),
                  if (selectedType != _AddItemType.goal) ...[
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedGoalId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Goal',
                      ),
                      items: skill.goals
                          .map(
                            (goal) => DropdownMenuItem<String>(
                              value: goal.id,
                              child: Text(
                                goal.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: skill.goals.isEmpty
                          ? null
                          : (value) {
                              setSheetState(() {
                                selectedGoalId = value;
                                final matchingGoal = skill.goals.firstWhere(
                                  (goal) => goal.id == value,
                                );
                                selectedTaskId = matchingGoal.tasks.isNotEmpty
                                    ? matchingGoal.tasks.first.id
                                    : null;
                              });
                            },
                    ),
                  ],
                  if (selectedType == _AddItemType.subtask) ...[
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedTaskId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Task',
                      ),
                      items: tasks
                          .map(
                            (task) => DropdownMenuItem<String>(
                              value: task.id,
                              child: Text(
                                task.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: tasks.isEmpty
                          ? null
                          : (value) {
                              setSheetState(() {
                                selectedTaskId = value;
                              });
                            },
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        switch (selectedType) {
                          case _AddItemType.goal:
                            store.addGoal(widget.skillId, controller.text);
                          case _AddItemType.task:
                            if (selectedGoalId != null) {
                              store.addTask(
                                skillId: widget.skillId,
                                goalId: selectedGoalId!,
                                title: controller.text,
                              );
                            }
                          case _AddItemType.subtask:
                            if (selectedGoalId != null && selectedTaskId != null) {
                              store.addSubtask(
                                skillId: widget.skillId,
                                goalId: selectedGoalId!,
                                taskId: selectedTaskId!,
                                title: controller.text,
                              );
                            }
                        }
                        Navigator.of(sheetContext).pop();
                      },
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showRenameDialog({
    required BuildContext context,
    required String title,
    required String initialValue,
    required Future<void> Function(String value) onSave,
  }) async {
    final controller = TextEditingController(text: initialValue);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final isDark = Theme.of(dialogContext).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1B2433) : Colors.white,
          title: Text(
            title,
            style: TextStyle(
              color: isDark ? const Color(0xFFF5F7FB) : const Color(0xFF2A3243),
            ),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              hintText: 'Enter title',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                await onSave(controller.text);
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showSkillTitleDialog(
    BuildContext context,
    String currentTitle,
  ) async {
    await _showRenameDialog(
      context: context,
      title: 'Edit Skill Title',
      initialValue: currentTitle,
      onSave: (value) => widget.store.updateSkillTitle(widget.skillId, value),
    );
  }

  Future<void> _confirmDeleteSkill(
    BuildContext context,
    String skillTitle,
  ) async {
    final shouldDelete = await _showDeleteConfirmation(
      context: context,
      title: 'Delete skill?',
      message:
          'Are you sure you want to delete "$skillTitle" and everything inside it?',
      confirmLabel: 'Delete',
      cancelLabel: 'Cancel',
    );

    if (!shouldDelete || !context.mounted) {
      return;
    }

    Navigator.of(context).pop();
    await widget.store.deleteSkill(widget.skillId);
  }

  Future<void> _showMoveTaskDialog({
    required BuildContext context,
    required String skillTitle,
    required GoalItem currentGoal,
    required TaskItem task,
  }) async {
    final skill = widget.store.skillById(widget.skillId);
    final destinationGoals = skill.goals
        .where((goal) => goal.id != currentGoal.id)
        .toList(growable: false);

    if (destinationGoals.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add another goal first so this task has somewhere to move.'),
        ),
      );
      return;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedGoalId = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1B2433) : Colors.white,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                18,
                8,
                18,
                MediaQuery.of(sheetContext).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Move "${task.title}"',
                    style: TextStyle(
                      color: isDark ? const Color(0xFFF5F7FB) : const Color(0xFF263041),
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Choose a goal in $skillTitle',
                    style: TextStyle(
                      color: isDark ? const Color(0xFF9FAACA) : const Color(0xFF7C879B),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ...destinationGoals.map(
                    (goal) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(goal.title),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => Navigator.of(sheetContext).pop(goal.id),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (selectedGoalId == null) {
      return;
    }

    await widget.store.moveTaskToGoal(
      skillId: widget.skillId,
      fromGoalId: currentGoal.id,
      toGoalId: selectedGoalId,
      taskId: task.id,
    );
  }

  Future<void> _showTaskEditOptions({
    required BuildContext context,
    required TaskItem task,
    required GoalItem currentGoal,
    required String skillTitle,
  }) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1B2433) : Colors.white,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                18,
                8,
                18,
                MediaQuery.of(sheetContext).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      color: isDark ? const Color(0xFFF5F7FB) : const Color(0xFF263041),
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.edit_rounded),
                    title: const Text('Change name'),
                    onTap: () async {
                      Navigator.of(sheetContext).pop();
                      await _showRenameDialog(
                        context: context,
                        title: 'Edit Task Title',
                        initialValue: task.title,
                        onSave: (value) => widget.store.updateTaskTitle(
                          skillId: widget.skillId,
                          goalId: currentGoal.id,
                          taskId: task.id,
                          title: value,
                        ),
                      );
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.swap_horiz_rounded),
                    title: const Text('Move to different goal'),
                    onTap: () async {
                      Navigator.of(sheetContext).pop();
                      await _showMoveTaskDialog(
                        context: context,
                        skillTitle: skillTitle,
                        currentGoal: currentGoal,
                        task: task,
                      );
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.delete_outline_rounded,
                      color: Color(0xFFE35D6A),
                    ),
                    title: const Text('Delete task'),
                    onTap: () async {
                      Navigator.of(sheetContext).pop();
                      final shouldDelete = await _showDeleteConfirmation(
                        context: context,
                        title: 'Delete task?',
                        message: 'This will remove "${task.title}" and all of its subtasks.',
                      );
                      if (shouldDelete) {
                        await widget.store.deleteTask(
                          skillId: widget.skillId,
                          goalId: currentGoal.id,
                          taskId: task.id,
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showGoalEditOptions({
    required BuildContext context,
    required GoalItem goal,
  }) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1B2433) : Colors.white,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                18,
                8,
                18,
                MediaQuery.of(sheetContext).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    goal.title,
                    style: TextStyle(
                      color: isDark ? const Color(0xFFF5F7FB) : const Color(0xFF263041),
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.edit_rounded),
                    title: const Text('Change name'),
                    onTap: () async {
                      Navigator.of(sheetContext).pop();
                      await _showRenameDialog(
                        context: context,
                        title: 'Edit Goal Title',
                        initialValue: goal.title,
                        onSave: (value) => widget.store.updateGoalTitle(
                          skillId: widget.skillId,
                          goalId: goal.id,
                          title: value,
                        ),
                      );
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.delete_outline_rounded,
                      color: Color(0xFFE35D6A),
                    ),
                    title: const Text('Delete goal'),
                    onTap: () async {
                      Navigator.of(sheetContext).pop();
                      final shouldDelete = await _showDeleteConfirmation(
                        context: context,
                        title: 'Delete goal?',
                        message: 'This will remove "${goal.title}" and everything inside it.',
                      );
                      if (shouldDelete) {
                        await widget.store.deleteGoal(
                          skillId: widget.skillId,
                          goalId: goal.id,
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showSubtaskEditOptions({
    required BuildContext context,
    required GoalItem goal,
    required TaskItem task,
    required SubtaskItem subtask,
  }) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1B2433) : Colors.white,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                18,
                8,
                18,
                MediaQuery.of(sheetContext).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subtask.title,
                    style: TextStyle(
                      color: isDark ? const Color(0xFFF5F7FB) : const Color(0xFF263041),
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.edit_rounded),
                    title: const Text('Change name'),
                    onTap: () async {
                      Navigator.of(sheetContext).pop();
                      await _showRenameDialog(
                        context: context,
                        title: 'Edit Subtask Title',
                        initialValue: subtask.title,
                        onSave: (value) => widget.store.updateSubtaskTitle(
                          skillId: widget.skillId,
                          goalId: goal.id,
                          taskId: task.id,
                          subtaskId: subtask.id,
                          title: value,
                        ),
                      );
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.delete_outline_rounded,
                      color: Color(0xFFE35D6A),
                    ),
                    title: const Text('Delete subtask'),
                    onTap: () async {
                      Navigator.of(sheetContext).pop();
                      final shouldDelete = await _showDeleteConfirmation(
                        context: context,
                        title: 'Delete subtask?',
                        message: 'This will remove "${subtask.title}".',
                      );
                      if (shouldDelete) {
                        await widget.store.deleteSubtask(
                          skillId: widget.skillId,
                          goalId: goal.id,
                          taskId: task.id,
                          subtaskId: subtask.id,
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<bool> _showDeleteConfirmation({
    required BuildContext context,
    required String title,
    required String message,
    String confirmLabel = 'Delete',
    String cancelLabel = 'Cancel',
  }) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1B2433) : Colors.white,
          title: Text(
            title,
            style: TextStyle(
              color: isDark ? const Color(0xFFF5F7FB) : const Color(0xFF2A3243),
            ),
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(cancelLabel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFE35D6A),
                foregroundColor: Colors.white,
              ),
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }
}

enum _AddItemType {
  goal('Goal'),
  task('Task'),
  subtask('Subtask');

  const _AddItemType(this.label);

  final String label;
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B2433) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.24)
                : const Color(0xFF2A334A).withValues(alpha: 0.06),
            blurRadius: 22,
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
              color: isDark ? const Color(0xFFF5F7FB) : const Color(0xFF30394C),
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.store,
    required this.skillId,
    required this.goalIndex,
    required this.goal,
    required this.onEdit,
    required this.onEditTask,
    required this.onEditSubtask,
  });

  final AppStore store;
  final String skillId;
  final int goalIndex;
  final GoalItem goal;
  final VoidCallback onEdit;
  final void Function(TaskItem task) onEditTask;
  final void Function(TaskItem task, SubtaskItem subtask) onEditSubtask;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B2433) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.24)
                : const Color(0xFF2A334A).withValues(alpha: 0.06),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          _ItemRow(
            title: goal.title,
            leading: Icon(
              Icons.gps_fixed_rounded,
              color: goal.isComplete ? const Color(0xFF36B96E) : const Color(0xFFFF5F57),
            ),
            isComplete: goal.isComplete,
            onEdit: onEdit,
            dragHandle: ReorderableDragStartListener(
              index: goalIndex,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 2),
                child: Icon(
                  Icons.drag_handle_rounded,
                  size: 20,
                  color: Color(0xFFB0B9CA),
                ),
              ),
            ),
            onToggleComplete: () {
              store.toggleGoalComplete(
                skillId: skillId,
                goalId: goal.id,
              );
            },
            onToggleExpanded: goal.tasks.isEmpty
                ? null
                : () {
                    store.toggleGoalExpanded(
                      skillId: skillId,
                      goalId: goal.id,
                    );
                  },
            isExpanded: goal.isExpanded,
          ),
          if (goal.isExpanded && goal.tasks.isNotEmpty)
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              itemCount: goal.tasks.length,
              onReorder: (oldIndex, newIndex) {
                store.reorderTasks(
                  skillId: skillId,
                  goalId: goal.id,
                  oldIndex: oldIndex,
                  newIndex: newIndex,
                );
              },
              itemBuilder: (context, index) {
                final task = goal.tasks[index];
                return Column(
                  key: ValueKey(task.id),
                  children: [
                    Divider(
                      height: 1,
                      color: isDark ? const Color(0xFF2B3648) : null,
                    ),
                    _TaskSection(
                      store: store,
                      skillId: skillId,
                      goalId: goal.id,
                      task: task,
                      taskIndex: index,
                      onEdit: () => onEditTask(task),
                      onEditSubtask: (subtask) => onEditSubtask(task, subtask),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

class _TaskSection extends StatelessWidget {
  const _TaskSection({
    required this.store,
    required this.skillId,
    required this.goalId,
    required this.task,
    required this.taskIndex,
    required this.onEdit,
    required this.onEditSubtask,
  });

  final AppStore store;
  final String skillId;
  final String goalId;
  final TaskItem task;
  final int taskIndex;
  final VoidCallback onEdit;
  final void Function(SubtaskItem subtask) onEditSubtask;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        _ItemRow(
          title: task.title,
          leading: Icon(
            Icons.circle_outlined,
            color: task.isComplete ? const Color(0xFF36B96E) : const Color(0xFF5B667C),
          ),
          padding: const EdgeInsets.only(left: 22, right: 10, top: 13, bottom: 13),
          isComplete: task.isComplete,
          onEdit: onEdit,
          dragHandle: ReorderableDragStartListener(
            index: taskIndex,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 2),
              child: Icon(
                Icons.drag_handle_rounded,
                size: 20,
                color: Color(0xFFB0B9CA),
              ),
            ),
          ),
          onToggleComplete: () {
            store.toggleTaskComplete(
              skillId: skillId,
              goalId: goalId,
              taskId: task.id,
            );
          },
          onToggleExpanded: task.subtasks.isEmpty
              ? null
              : () {
                  store.toggleTaskExpanded(
                    skillId: skillId,
                    goalId: goalId,
                    taskId: task.id,
                  );
                },
          isExpanded: task.isExpanded,
        ),
        if (task.isExpanded && task.subtasks.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 40, right: 12, bottom: 12),
            child: ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              itemCount: task.subtasks.length,
              onReorder: (oldIndex, newIndex) {
                store.reorderSubtasks(
                  skillId: skillId,
                  goalId: goalId,
                  taskId: task.id,
                  oldIndex: oldIndex,
                  newIndex: newIndex,
                );
              },
              itemBuilder: (context, index) {
                final subtask = task.subtasks[index];
                return Container(
                  key: ValueKey(subtask.id),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: isDark
                            ? const Color(0xFF334058)
                            : const Color(0xFFD9DFEA),
                        width: 1.5,
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 14),
                    child: Row(
                      children: [
                        Text(
                          '-',
                          style: TextStyle(
                            color: subtask.isComplete
                                ? const Color(0xFF36B96E)
                                : const Color(0xFFB8C1D3),
                            fontSize: 24,
                            fontWeight: FontWeight.w400,
                            height: 1,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            subtask.title,
                            style: TextStyle(
                              color: isDark
                                  ? const Color(0xFFE5EAF4)
                                  : const Color(0xFF404A5E),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              decoration: subtask.isComplete
                                  ? TextDecoration.lineThrough
                                  : null,
                              decorationColor: const Color(0xFF36B96E),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => onEditSubtask(subtask),
                          icon: const Icon(
                            Icons.edit_rounded,
                            size: 18,
                            color: Color(0xFF8A95A9),
                          ),
                          splashRadius: 18,
                          visualDensity: VisualDensity.compact,
                        ),
                        ReorderableDragStartListener(
                          index: index,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 2),
                            child: Icon(
                              Icons.drag_handle_rounded,
                              size: 20,
                              color: Color(0xFFB0B9CA),
                            ),
                          ),
                        ),
                        _StatusButton(
                          isComplete: subtask.isComplete,
                          onTap: () {
                            store.toggleSubtaskComplete(
                              skillId: skillId,
                              goalId: goalId,
                              taskId: task.id,
                              subtaskId: subtask.id,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({
    required this.title,
    required this.leading,
    required this.isComplete,
    required this.onEdit,
    required this.onToggleComplete,
    required this.onToggleExpanded,
    required this.isExpanded,
    this.dragHandle,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
  });

  final String title;
  final Widget leading;
  final bool isComplete;
  final VoidCallback onEdit;
  final VoidCallback onToggleComplete;
  final VoidCallback? onToggleExpanded;
  final bool isExpanded;
  final Widget? dragHandle;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: padding,
      child: Row(
        children: [
          leading,
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: isDark ? const Color(0xFFE5EAF4) : const Color(0xFF404A5E),
                fontSize: 16,
                fontWeight: FontWeight.w600,
                decoration: isComplete ? TextDecoration.lineThrough : null,
                decorationColor: const Color(0xFF36B96E),
              ),
            ),
          ),
          IconButton(
            onPressed: onEdit,
            icon: const Icon(
              Icons.edit_rounded,
              size: 18,
              color: Color(0xFF8A95A9),
            ),
            splashRadius: 18,
            visualDensity: VisualDensity.compact,
          ),
          ...(dragHandle != null ? [dragHandle!] : const <Widget>[]),
          _StatusButton(
            isComplete: isComplete,
            onTap: onToggleComplete,
          ),
          const SizedBox(width: 4),
          IconButton(
            onPressed: onToggleExpanded,
            icon: Icon(
              isExpanded ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_up_rounded,
              color: onToggleExpanded == null
                  ? (isDark ? const Color(0xFF43506B) : const Color(0xFFD0D7E4))
                  : (isDark ? const Color(0xFF9FAACA) : const Color(0xFF76839A)),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusButton extends StatelessWidget {
  const _StatusButton({
    required this.isComplete,
    required this.onTap,
  });

  final bool isComplete;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isComplete
              ? (isDark ? const Color(0xFF173325) : const Color(0xFFECFAF1))
              : (isDark ? const Color(0xFF202A3C) : Colors.white),
          border: Border.all(
            color: isComplete
                ? const Color(0xFF36B96E)
                : (isDark ? const Color(0xFF334058) : const Color(0xFFDCE2EE)),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: isDark ? 12 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          isComplete ? Icons.check_rounded : Icons.add_rounded,
          color: isComplete ? const Color(0xFF36B96E) : const Color(0xFF8A95A9),
          size: 20,
        ),
      ),
    );
  }
}
