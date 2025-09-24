class Project {
  final String id;
  final String name;
  final String description;
  final DateTime createdAt;
  final ProjectStatus status;

  Project({
    required this.id,
    required this.name,
    required this.description,
    required this.createdAt,
    this.status = ProjectStatus.inProgress,
  });

  Project copyWith({
    String? id,
    String? name,
    String? description,
    DateTime? createdAt,
    ProjectStatus? status,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'status': status.name,
    };
  }

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      createdAt: DateTime.parse(json['createdAt']),
      status: ProjectStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ProjectStatus.inProgress,
      ),
    );
  }

  @override
  String toString() {
    return 'Project(id: $id, name: $name, description: $description, createdAt: $createdAt, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Project &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.createdAt == createdAt &&
        other.status == status;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        description.hashCode ^
        createdAt.hashCode ^
        status.hashCode;
  }
}

enum ProjectStatus {
  inProgress,
  completed,
  onHold,
  cancelled,
}

extension ProjectStatusExtension on ProjectStatus {
  String get displayName {
    switch (this) {
      case ProjectStatus.inProgress:
        return 'In Corso';
      case ProjectStatus.completed:
        return 'Completato';
      case ProjectStatus.onHold:
        return 'In Pausa';
      case ProjectStatus.cancelled:
        return 'Annullato';
    }
  }

  String get emoji {
    switch (this) {
      case ProjectStatus.inProgress:
        return '🚧';
      case ProjectStatus.completed:
        return '✅';
      case ProjectStatus.onHold:
        return '⏸️';
      case ProjectStatus.cancelled:
        return '❌';
    }
  }
}
