import 'package:flutter/foundation.dart';

@immutable
class Project {
  final String id;
  final String name;
  final String clientName;
  final String location;
  final DateTime createdAt;
  final String refNumber;
  final String? industry;
  /// null = no filter, 'Value' or 'Premium'
  final String? tier;
  final List<String> areas;

  const Project({
    required this.id,
    required this.name,
    required this.clientName,
    required this.location,
    required this.createdAt,
    required this.refNumber,
    this.industry,
    this.tier,
    this.areas = const [],
  });

  Project copyWith({
    String? id,
    String? name,
    String? clientName,
    String? location,
    DateTime? createdAt,
    String? refNumber,
    String? industry,
    String? tier,
    List<String>? areas,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      clientName: clientName ?? this.clientName,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
      refNumber: refNumber ?? this.refNumber,
      industry: industry ?? this.industry,
      tier: tier ?? this.tier,
      areas: areas ?? this.areas,
    );
  }

  factory Project.fromMap(Map<String, dynamic> m) {
    final refNumber = m['Ref. Number']?.toString() ?? '';
    final industry = m['Industry']?.toString().trim();
    final tier = m['Tier']?.toString().trim();
    final areasRaw = m['Areas']?.toString().trim() ?? '';
    final areas = areasRaw.isEmpty
        ? <String>[]
        : areasRaw.split(',').map((a) => a.trim()).where((a) => a.isNotEmpty).toList();
    return Project(
      id: refNumber,
      refNumber: refNumber,
      name: m['Project Name']?.toString() ?? '',
      clientName: m['Client Name']?.toString() ?? '',
      location: m['Location']?.toString() ?? '',
      createdAt: m['Created At'] != null
          ? DateTime.tryParse(m['Created At'].toString()) ?? DateTime.now()
          : DateTime.now(),
      industry: (industry?.isEmpty ?? true) ? null : industry,
      tier: (tier?.isEmpty ?? true) ? null : tier,
      areas: areas,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Project && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
