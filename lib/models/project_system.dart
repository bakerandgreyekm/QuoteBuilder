import 'package:flutter/foundation.dart';

@immutable
class ProjectSystem {
  final String projectId;
  final String systemType;

  const ProjectSystem({
    required this.projectId,
    required this.systemType,
  });

  ProjectSystem copyWith({String? projectId, String? systemType}) {
    return ProjectSystem(
      projectId: projectId ?? this.projectId,
      systemType: systemType ?? this.systemType,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectSystem &&
          runtimeType == other.runtimeType &&
          projectId == other.projectId &&
          systemType == other.systemType;

  @override
  int get hashCode => Object.hash(projectId, systemType);
}
