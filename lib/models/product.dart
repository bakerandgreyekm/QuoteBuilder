import 'package:flutter/foundation.dart';

@immutable
class Product {
  final String id;
  final String category;
  final String name;
  final String brand;
  final String unit;
  final double rate;

  const Product({
    required this.id,
    required this.category,
    required this.name,
    required this.brand,
    required this.unit,
    required this.rate,
  });

  factory Product.fromMap(Map<String, dynamic> m) {
    return Product(
      id: m['ID']?.toString() ?? '',
      category: m['Category']?.toString() ?? '',
      name: m['Product Name']?.toString() ?? '',
      brand: m['Brand']?.toString() ?? '',
      unit: m['Unit']?.toString() ?? '',
      rate: (m['Rate'] as num?)?.toDouble() ??
          double.tryParse(m['Rate']?.toString() ?? '0') ?? 0.0,
    );
  }

  Product copyWith({
    String? id,
    String? category,
    String? name,
    String? brand,
    String? unit,
    double? rate,
  }) {
    return Product(
      id: id ?? this.id,
      category: category ?? this.category,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      unit: unit ?? this.unit,
      rate: rate ?? this.rate,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Product && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
