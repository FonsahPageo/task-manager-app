import 'dart:convert';

/// Authentication payload returned by the backend (subset used by the app).
class AuthData {
  const AuthData({required this.token, required this.email, required this.fullName});

  final String token;
  final String email;
  final String fullName;

  factory AuthData.fromJson(Map<String, dynamic> json) => AuthData(
        token: json['token'] as String? ?? '',
        email: json['email'] as String? ?? '',
        fullName: json['fullName'] as String? ?? '',
      );

  Map<String, dynamic> toJson() =>
      {'token': token, 'email': email, 'fullName': fullName};

  static const _key = 'auth_data';
  static AuthData? fromStorage(String? raw) {
    if (raw == null) return null;
    try {
      return AuthData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}

enum TaskStatus {
  todo('TODO', 'To Do'),
  inProgress('IN_PROGRESS', 'In Progress'),
  done('DONE', 'Done');

  const TaskStatus(this.apiValue, this.label);
  final String apiValue;
  final String label;

  static TaskStatus fromApi(String value) => TaskStatus.values.firstWhere(
        (s) => s.apiValue == value,
        orElse: () => TaskStatus.todo,
      );
}

class Task {
  const Task({required this.id, required this.title, required this.description, required this.status});

  final int id;
  final String title;
  final String? description;
  final TaskStatus status;

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        id: (json['id'] as num).toInt(),
        title: json['title'] as String,
        description: json['description'] as String?,
        status: TaskStatus.fromApi(json['status'] as String),
      );
}

class TaskDraft {
  const TaskDraft({required this.title, required this.description, required this.status});

  final String title;
  final String? description;
  final TaskStatus status;

  Map<String, dynamic> toJson() =>
      {'title': title, 'description': description, 'status': status.apiValue};
}
