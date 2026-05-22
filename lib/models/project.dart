import 'package:flutter/foundation.dart';

@immutable
class Project {
  final String id;
  final String name;
  final String clientName;
  final String location;
  final DateTime createdAt;
  final String refNumber;

  const Project({
    required this.id,
    required this.name,
    required this.clientName,
    required this.location,
    required this.createdAt,
    required this.refNumber,
  });

  Project copyWith({
    String? id,
    String? name,
    String? clientName,
    String? location,
    DateTime? createdAt,
    String? refNumber,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      clientName: clientName ?? this.clientName,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
      refNumber: refNumber ?? this.refNumber,
    );
  }

  factory Project.fromMap(Map<String, dynamic> m) {
    final refNumber = m['Ref. Number']?.toString() ?? '';
    return Project(
      id: refNumber,
      refNumber: refNumber,
      name: m['Project Name']?.toString() ?? '',
      clientName: m['Client Name']?.toString() ?? '',
      location: m['Location']?.toString() ?? '',
      createdAt: m['Created At'] != null
          ? DateTime.tryParse(m['Created At'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Project && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
