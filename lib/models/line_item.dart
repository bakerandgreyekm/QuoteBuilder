import 'package:flutter/foundation.dart';

@immutable
class LineItem {
  final String id;
  final String projectId;
  final String systemType;
  final String category;
  final String productName;
  final String brand;
  final String unit;
  final int quantity;
  final double rate;
  final String noteText;

  const LineItem({
    required this.id,
    required this.projectId,
    required this.systemType,
    required this.category,
    required this.productName,
    required this.brand,
    required this.unit,
    required this.quantity,
    required this.rate,
    this.noteText = '',
  });

  double get amount => quantity * rate;

  factory LineItem.fromMap(Map<String, dynamic> m, String projectId) {
    return LineItem(
      id: m['ID']?.toString() ?? '',
      projectId: projectId,
      systemType: m['System Type']?.toString() ?? '',
      category: m['Category']?.toString() ?? '',
      productName: m['Product Name']?.toString() ?? '',
      brand: m['Brand']?.toString() ?? '',
      unit: m['Unit']?.toString() ?? '',
      quantity: (m['Quantity'] as num?)?.toInt() ??
          int.tryParse(m['Quantity']?.toString() ?? '0') ?? 0,
      rate: (m['Rate'] as num?)?.toDouble() ??
          double.tryParse(m['Rate']?.toString() ?? '0') ?? 0.0,
      noteText: m['Note']?.toString() ?? '',
    );
  }

  LineItem copyWith({
    String? id,
    String? projectId,
    String? systemType,
    String? category,
    String? productName,
    String? brand,
    String? unit,
    int? quantity,
    double? rate,
    String? noteText,
  }) {
    return LineItem(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      systemType: systemType ?? this.systemType,
      category: category ?? this.category,
      productName: productName ?? this.productName,
      brand: brand ?? this.brand,
      unit: unit ?? this.unit,
      quantity: quantity ?? this.quantity,
      rate: rate ?? this.rate,
      noteText: noteText ?? this.noteText,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LineItem && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
