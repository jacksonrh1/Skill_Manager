import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/profile_data.dart';
import '../models/skill.dart';
import '../models/task_item.dart';

class AppStore extends ChangeNotifier {
  static const String _themeModeKey = 'theme_mode_dark';

  AppStore._(
    this._prefs,
    this._auth,
    this._firestore,
  );

  final SharedPreferences _prefs;
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
      _profileSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _skillsSubscription;

  bool isReady = false;
  bool isDarkMode = false;

  ProfileData profile = const ProfileData(
    name: 'John Doe',
    avatarIndex: 0,
    avatarImagePath: null,
  );

  List<Skill> skills = <Skill>[];

  User? get currentUser => _auth.currentUser;
  bool get isAuthenticated => currentUser != null;

  static Future<AppStore> load() async {
    final prefs = await SharedPreferences.getInstance();
    final store = AppStore._(
      prefs,
      FirebaseAuth.instance,
      FirebaseFirestore.instance,
    );
    store.isDarkMode = prefs.getBool(_themeModeKey) ?? false;
    await store._initialize();
    return store;
  }

  Skill skillById(String skillId) {
    return skills.firstWhere((skill) => skill.id == skillId);
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user;
    if (user == null) {
      return;
    }

    await _userDoc(user.uid).set({
      'name': name.trim().isEmpty ? _defaultNameFromEmail(email) : name.trim(),
      'avatarIndex': 0,
      'email': email.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> updateThemeMode(bool darkMode) async {
    if (isDarkMode == darkMode) {
      return;
    }

    isDarkMode = darkMode;
    notifyListeners();
    await _prefs.setBool(_themeModeKey, darkMode);
  }

  Future<void> deleteAccount() async {
    final user = currentUser;
    if (user == null) {
      return;
    }

    final avatarPath = profile.avatarImagePath;
    final skillsSnapshot = await _skillsCollection(user.uid).get();
    final batch = _firestore.batch();

    for (final doc in skillsSnapshot.docs) {
      batch.delete(doc.reference);
    }

    batch.delete(_userDoc(user.uid));
    await batch.commit();

    final avatarKey = _avatarPathKey(user.uid);
    if (avatarKey != null) {
      await _prefs.remove(avatarKey);
    }
    if (avatarPath != null) {
      await _deleteFileIfExists(avatarPath);
    }

    await user.delete();
  }

  Future<void> updateProfileName(String name) async {
    final trimmed = name.trim();
    final user = currentUser;
    if (trimmed.isEmpty || user == null) {
      return;
    }

    profile = profile.copyWith(name: trimmed);
    notifyListeners();

    await _userDoc(user.uid).set({
      'name': trimmed,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updateAvatarIndex(int avatarIndex) async {
    final user = currentUser;
    profile = profile.copyWith(avatarIndex: avatarIndex);
    notifyListeners();

    if (user == null) {
      return;
    }

    await _userDoc(user.uid).set({
      'avatarIndex': avatarIndex,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updateAvatarImagePath(String imagePath) async {
    final previousPath = profile.avatarImagePath;
    profile = profile.copyWith(avatarImagePath: imagePath);
    notifyListeners();

    final key = _avatarPathKey(currentUser?.uid);
    if (key != null) {
      await _prefs.setString(key, imagePath);
    }

    if (previousPath != null && previousPath != imagePath) {
      await _deleteFileIfExists(previousPath);
    }
  }

  Future<void> clearAvatarImagePath() async {
    final previousPath = profile.avatarImagePath;
    if (previousPath == null) {
      return;
    }

    profile = profile.copyWith(clearAvatarImagePath: true);
    notifyListeners();

    final key = _avatarPathKey(currentUser?.uid);
    if (key != null) {
      await _prefs.remove(key);
    }

    await _deleteFileIfExists(previousPath);
  }

  Future<void> addSkill(String title) async {
    final user = currentUser;
    final trimmed = title.trim();
    if (user == null || trimmed.isEmpty) {
      return;
    }

    final skill = Skill.create(
      id: _skillsCollection(user.uid).doc().id,
      title: trimmed,
      notes: '',
      sortOrder: skills.length,
    );

    skills = [...skills, skill];
    notifyListeners();
    await _syncSkill(user.uid, skill);
  }

  Future<void> deleteSkill(String skillId) async {
    final user = currentUser;
    if (user == null) {
      return;
    }

    skills = skills.where((skill) => skill.id != skillId).toList();
    notifyListeners();
    await _skillsCollection(user.uid).doc(skillId).delete();
  }

  Future<void> reorderSkills({
    required int oldIndex,
    required int newIndex,
  }) async {
    final user = currentUser;
    if (user == null) {
      return;
    }

    final reorderedSkills = List<Skill>.from(skills);
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final moved = reorderedSkills.removeAt(oldIndex);
    reorderedSkills.insert(newIndex, moved);

    skills = reorderedSkills
        .asMap()
        .entries
        .map((entry) => entry.value.copyWith(sortOrder: entry.key))
        .toList();
    notifyListeners();

    for (final skill in skills) {
      await _syncSkill(user.uid, skill);
    }
  }

  Future<void> updateSkillNotes(String skillId, String notes) async {
    await _updateSkill(
      skillId,
      (skill) => skill.copyWith(notes: notes),
    );
  }

  Future<void> updateSkillTitle(String skillId, String title) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) {
      return;
    }

    await _updateSkill(
      skillId,
      (skill) => skill.copyWith(title: trimmed),
    );
  }

  Future<void> addGoal(String skillId, String title) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) {
      return;
    }

    await _updateSkill(
      skillId,
      (skill) => skill.copyWith(
        goals: [
          ...skill.goals,
          GoalItem.create(
            id: _newId('goal'),
            title: trimmed,
          ),
        ],
      ),
    );
  }

  Future<void> reorderGoals({
    required String skillId,
    required int oldIndex,
    required int newIndex,
  }) async {
    await _updateSkill(
      skillId,
      (skill) {
        final goals = List<GoalItem>.from(skill.goals);
        if (newIndex > oldIndex) {
          newIndex -= 1;
        }
        final moved = goals.removeAt(oldIndex);
        goals.insert(newIndex, moved);
        return skill.copyWith(goals: goals);
      },
    );
  }

  Future<void> addTask({
    required String skillId,
    required String goalId,
    required String title,
  }) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) {
      return;
    }

    await _updateSkill(
      skillId,
      (skill) => skill.copyWith(
        goals: skill.goals.map((goal) {
          if (goal.id != goalId) {
            return goal;
          }
          final updatedGoal = goal.copyWith(
            tasks: [
              ...goal.tasks,
              TaskItem.create(
                id: _newId('task'),
                title: trimmed,
              ),
            ],
          );
          return updatedGoal;
        }).toList(),
      ),
    );
  }

  Future<void> addSubtask({
    required String skillId,
    required String goalId,
    required String taskId,
    required String title,
  }) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) {
      return;
    }

    await _updateSkill(
      skillId,
      (skill) => skill.copyWith(
        goals: skill.goals.map((goal) {
          if (goal.id != goalId) {
            return goal;
          }
          final updatedGoal = goal.copyWith(
            tasks: goal.tasks.map((task) {
              if (task.id != taskId) {
                return task;
              }
              final updatedTask = task.copyWith(
                subtasks: [
                  ...task.subtasks,
                  SubtaskItem.create(
                    id: _newId('subtask'),
                    title: trimmed,
                  ),
                ],
              );
              return updatedTask;
            }).toList(),
          );
          return updatedGoal;
        }).toList(),
      ),
    );
  }

  Future<void> updateGoalTitle({
    required String skillId,
    required String goalId,
    required String title,
  }) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) {
      return;
    }

    await _updateSkill(
      skillId,
      (skill) => skill.copyWith(
        goals: skill.goals.map((goal) {
          if (goal.id != goalId) {
            return goal;
          }
          return goal.copyWith(title: trimmed);
        }).toList(),
      ),
    );
  }

  Future<void> deleteGoal({
    required String skillId,
    required String goalId,
  }) async {
    await _updateSkill(
      skillId,
      (skill) => skill.copyWith(
        goals: skill.goals.where((goal) => goal.id != goalId).toList(),
      ),
    );
  }

  Future<void> updateTaskTitle({
    required String skillId,
    required String goalId,
    required String taskId,
    required String title,
  }) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) {
      return;
    }

    await _updateSkill(
      skillId,
      (skill) => skill.copyWith(
        goals: skill.goals.map((goal) {
          if (goal.id != goalId) {
            return goal;
          }
          return goal.copyWith(
            tasks: goal.tasks.map((task) {
              if (task.id != taskId) {
                return task;
              }
              return task.copyWith(title: trimmed);
            }).toList(),
          );
        }).toList(),
      ),
    );
  }

  Future<void> deleteTask({
    required String skillId,
    required String goalId,
    required String taskId,
  }) async {
    await _updateSkill(
      skillId,
      (skill) => skill.copyWith(
        goals: skill.goals.map((goal) {
          if (goal.id != goalId) {
            return goal;
          }
          return goal.copyWith(
            tasks: goal.tasks.where((task) => task.id != taskId).toList(),
          );
        }).toList(),
      ),
    );
  }

  Future<void> updateSubtaskTitle({
    required String skillId,
    required String goalId,
    required String taskId,
    required String subtaskId,
    required String title,
  }) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) {
      return;
    }

    await _updateSkill(
      skillId,
      (skill) => skill.copyWith(
        goals: skill.goals.map((goal) {
          if (goal.id != goalId) {
            return goal;
          }
          return goal.copyWith(
            tasks: goal.tasks.map((task) {
              if (task.id != taskId) {
                return task;
              }
              return task.copyWith(
                subtasks: task.subtasks.map((subtask) {
                  if (subtask.id != subtaskId) {
                    return subtask;
                  }
                  return subtask.copyWith(title: trimmed);
                }).toList(),
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }

  Future<void> deleteSubtask({
    required String skillId,
    required String goalId,
    required String taskId,
    required String subtaskId,
  }) async {
    await _updateSkill(
      skillId,
      (skill) => skill.copyWith(
        goals: skill.goals.map((goal) {
          if (goal.id != goalId) {
            return goal;
          }
          return goal.copyWith(
            tasks: goal.tasks.map((task) {
              if (task.id != taskId) {
                return task;
              }
              return task.copyWith(
                subtasks: task.subtasks
                    .where((subtask) => subtask.id != subtaskId)
                    .toList(),
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }

  Future<void> reorderTasks({
    required String skillId,
    required String goalId,
    required int oldIndex,
    required int newIndex,
  }) async {
    await _updateSkill(
      skillId,
      (skill) => skill.copyWith(
        goals: skill.goals.map((goal) {
          if (goal.id != goalId) {
            return goal;
          }
          final tasks = List<TaskItem>.from(goal.tasks);
          if (newIndex > oldIndex) {
            newIndex -= 1;
          }
          final moved = tasks.removeAt(oldIndex);
          tasks.insert(newIndex, moved);
          return goal.copyWith(tasks: tasks);
        }).toList(),
      ),
    );
  }

  Future<void> moveTaskToGoal({
    required String skillId,
    required String fromGoalId,
    required String toGoalId,
    required String taskId,
  }) async {
    if (fromGoalId == toGoalId) {
      return;
    }

    await _updateSkill(
      skillId,
      (skill) {
        TaskItem? movedTask;

        final updatedGoals = skill.goals.map((goal) {
          if (goal.id == fromGoalId) {
            final remainingTasks = List<TaskItem>.from(goal.tasks);
            final index = remainingTasks.indexWhere((task) => task.id == taskId);
            if (index != -1) {
              movedTask = remainingTasks.removeAt(index);
            }
            return goal.copyWith(tasks: remainingTasks);
          }
          return goal;
        }).toList();

        if (movedTask == null) {
          return skill;
        }

        return skill.copyWith(
          goals: updatedGoals.map((goal) {
            if (goal.id != toGoalId) {
              return goal;
            }
            return goal.copyWith(
              isExpanded: true,
              tasks: [...goal.tasks, movedTask!],
            );
          }).toList(),
        );
      },
    );
  }

  Future<void> reorderSubtasks({
    required String skillId,
    required String goalId,
    required String taskId,
    required int oldIndex,
    required int newIndex,
  }) async {
    await _updateSkill(
      skillId,
      (skill) => skill.copyWith(
        goals: skill.goals.map((goal) {
          if (goal.id != goalId) {
            return goal;
          }
          return goal.copyWith(
            tasks: goal.tasks.map((task) {
              if (task.id != taskId) {
                return task;
              }
              final subtasks = List<SubtaskItem>.from(task.subtasks);
              if (newIndex > oldIndex) {
                newIndex -= 1;
              }
              final moved = subtasks.removeAt(oldIndex);
              subtasks.insert(newIndex, moved);
              return task.copyWith(subtasks: subtasks);
            }).toList(),
          );
        }).toList(),
      ),
    );
  }

  Future<void> toggleGoalExpanded({
    required String skillId,
    required String goalId,
  }) async {
    await _updateSkill(
      skillId,
      (skill) => skill.copyWith(
        goals: skill.goals.map((goal) {
          if (goal.id != goalId) {
            return goal;
          }
          return goal.copyWith(isExpanded: !goal.isExpanded);
        }).toList(),
      ),
    );
  }

  Future<void> toggleTaskExpanded({
    required String skillId,
    required String goalId,
    required String taskId,
  }) async {
    await _updateSkill(
      skillId,
      (skill) => skill.copyWith(
        goals: skill.goals.map((goal) {
          if (goal.id != goalId) {
            return goal;
          }
          return goal.copyWith(
            tasks: goal.tasks.map((task) {
              if (task.id != taskId) {
                return task;
              }
              return task.copyWith(isExpanded: !task.isExpanded);
            }).toList(),
          );
        }).toList(),
      ),
    );
  }

  Future<void> toggleGoalComplete({
    required String skillId,
    required String goalId,
  }) async {
    await _updateSkill(
      skillId,
      (skill) => skill.copyWith(
        goals: skill.goals.map((goal) {
          if (goal.id != goalId) {
            return goal;
          }
          return goal.copyWith(isComplete: !goal.isComplete);
        }).toList(),
      ),
    );
  }

  Future<void> toggleTaskComplete({
    required String skillId,
    required String goalId,
    required String taskId,
  }) async {
    await _updateSkill(
      skillId,
      (skill) => skill.copyWith(
        goals: skill.goals.map((goal) {
          if (goal.id != goalId) {
            return goal;
          }
          final updatedGoal = goal.copyWith(
            tasks: goal.tasks.map((task) {
              if (task.id != taskId) {
                return task;
              }
              return task.copyWith(isComplete: !task.isComplete);
            }).toList(),
          );
          return updatedGoal;
        }).toList(),
      ),
    );
  }

  Future<void> toggleSubtaskComplete({
    required String skillId,
    required String goalId,
    required String taskId,
    required String subtaskId,
  }) async {
    await _updateSkill(
      skillId,
      (skill) => skill.copyWith(
        goals: skill.goals.map((goal) {
          if (goal.id != goalId) {
            return goal;
          }
          final updatedGoal = goal.copyWith(
            tasks: goal.tasks.map((task) {
              if (task.id != taskId) {
                return task;
              }
              final updatedTask = task.copyWith(
                subtasks: task.subtasks.map((subtask) {
                  if (subtask.id != subtaskId) {
                    return subtask;
                  }
                  return subtask.copyWith(isComplete: !subtask.isComplete);
                }).toList(),
              );
              return updatedTask;
            }).toList(),
          );
          return updatedGoal;
        }).toList(),
      ),
    );
  }

  Future<void> _initialize() async {
    _authSubscription = _auth.authStateChanges().listen(
      (user) async {
        await _handleAuthChanged(user);
      },
    );
    await _handleAuthChanged(_auth.currentUser);
  }

  Future<void> _handleAuthChanged(User? user) async {
    await _profileSubscription?.cancel();
    await _skillsSubscription?.cancel();

    if (user == null) {
      profile = const ProfileData(
        name: 'John Doe',
        avatarIndex: 0,
        avatarImagePath: null,
      );
      skills = <Skill>[];
      isReady = true;
      notifyListeners();
      return;
    }

    isReady = false;
    notifyListeners();

    await _ensureUserDocument(user);

    _profileSubscription = _userDoc(user.uid).snapshots().listen((snapshot) {
      final data = snapshot.data() ?? <String, dynamic>{};
      profile = ProfileData(
        name: data['name'] as String? ?? _defaultNameFromEmail(user.email),
        avatarIndex: data['avatarIndex'] as int? ?? 0,
        avatarImagePath: _prefs.getString(_avatarPathKey(user.uid)!),
      );
      isReady = true;
      notifyListeners();
    });

    _skillsSubscription = _skillsCollection(user.uid).snapshots().listen((snapshot) {
      skills = snapshot.docs
          .map((doc) => Skill.fromJson(doc.data()))
          .toList(growable: false)
        ..sort((a, b) {
          final orderCompare = a.sortOrder.compareTo(b.sortOrder);
          if (orderCompare != 0) {
            return orderCompare;
          }
          return a.title.compareTo(b.title);
        });
      isReady = true;
      notifyListeners();
    });
  }

  Future<void> _ensureUserDocument(User user) async {
    final doc = await _userDoc(user.uid).get();
    if (doc.exists) {
      return;
    }

    await _userDoc(user.uid).set({
      'name': _defaultNameFromEmail(user.email),
      'avatarIndex': 0,
      'email': user.email,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _updateSkill(
    String skillId,
    Skill Function(Skill skill) transform,
  ) async {
    final user = currentUser;
    if (user == null) {
      return;
    }

    Skill? changedSkill;
    skills = skills.map((skill) {
      if (skill.id != skillId) {
        return skill;
      }
      changedSkill = transform(skill);
      return changedSkill!;
    }).toList();
    notifyListeners();

    if (changedSkill != null) {
      await _syncSkill(user.uid, changedSkill!);
    }
  }

  Future<void> _syncSkill(String uid, Skill skill) async {
    await _skillsCollection(uid).doc(skill.id).set({
      ...skill.toJson(),
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) {
    return _firestore.collection('users').doc(uid);
  }

  CollectionReference<Map<String, dynamic>> _skillsCollection(String uid) {
    return _userDoc(uid).collection('skills');
  }

  String? _avatarPathKey(String? uid) {
    if (uid == null) {
      return null;
    }
    return 'avatar_image_path_$uid';
  }

  Future<void> _deleteFileIfExists(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  String _defaultNameFromEmail(String? email) {
    final value = email ?? 'User';
    final beforeAt = value.split('@').first.trim();
    if (beforeAt.isEmpty) {
      return 'User';
    }
    return beforeAt[0].toUpperCase() + beforeAt.substring(1);
  }

  static String _newId(String prefix) {
    return '$prefix-${DateTime.now().microsecondsSinceEpoch}';
  }

  @override
  Future<void> dispose() async {
    await _authSubscription?.cancel();
    await _profileSubscription?.cancel();
    await _skillsSubscription?.cancel();
    super.dispose();
  }
}
