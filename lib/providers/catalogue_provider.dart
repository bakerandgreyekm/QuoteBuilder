import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import 'sheets_service_provider.dart';

final systemTypeTagsProvider = FutureProvider<Map<String, List<String>>>((ref) {
  return ref.read(sheetsServiceProvider).getSystemTypeTags();
});

final systemIndustriesProvider = FutureProvider<Map<String, List<String>>>((ref) {
  return ref.read(sheetsServiceProvider).getSystemTypeIndustries();
});

final allIndustriesProvider = Provider<List<String>>((ref) {
  return ref.watch(systemIndustriesProvider).maybeWhen(
    data: (map) {
      final all = <String>{};
      for (final industries in map.values) {
        all.addAll(industries);
      }
      return all.toList()..sort();
    },
    orElse: () => [],
  );
});

final categoriesForSystemProvider = Provider.family<List<String>, String>((ref, systemType) {
  final tagsAsync = ref.watch(systemTypeTagsProvider);
  return tagsAsync.maybeWhen(
    data: (tags) {
      final relevant = tags[systemType] ?? [];
      if (relevant.isNotEmpty) return relevant;
      // fallback: show all categories if system type has no tags defined
      return ref.watch(catalogueProvider).maybeWhen(
        data: (list) => list.map((p) => p.category).toSet().toList()..sort(),
        orElse: () => [],
      );
    },
    orElse: () => [],
  );
});

class CatalogueNotifier extends AsyncNotifier<List<Product>> {
  @override
  Future<List<Product>> build() async {
    final raw = await ref.read(sheetsServiceProvider).getCatalogue();
    return raw.map((m) => Product.fromMap(m)).toList();
  }
}

// Full catalogue (used only as fallback when system type tags aren't configured)
final catalogueProvider =
    AsyncNotifierProvider<CatalogueNotifier, List<Product>>(
        CatalogueNotifier.new);

// Per-category lazy fetch — only loads when a category is actually selected
final catalogueByCategoryProvider =
    FutureProvider.family<List<Product>, String>((ref, category) async {
  final raw =
      await ref.read(sheetsServiceProvider).getCatalogueByCategory(category);
  return raw.map((m) => Product.fromMap(m)).toList();
});

final categoriesProvider = Provider<List<String>>((ref) {
  return ref.watch(catalogueProvider).maybeWhen(
    data: (list) => list.map((p) => p.category).toSet().toList()..sort(),
    orElse: () => [],
  );
});

final productsByCategoryProvider =
    Provider.family<List<Product>, String>((ref, category) {
  return ref.watch(catalogueByCategoryProvider(category)).maybeWhen(
    data: (list) => list,
    orElse: () => [],
  );
});

/// Returns products split into recommended (tier match + blank) and others.
/// When projectTier is null, all products are in recommended (no split).
final tieredProductsByCategoryProvider = Provider.family<
    ({List<Product> recommended, List<Product> others}),
    (String, String?)>((ref, args) {
  final (category, projectTier) = args;
  return ref.watch(catalogueByCategoryProvider(category)).maybeWhen(
    data: (products) {
      if (projectTier == null) {
        return (recommended: products, others: const []);
      }
      final recommended = <Product>[];
      final others = <Product>[];
      for (final p in products) {
        if (p.tier.isEmpty || p.tier == projectTier) {
          recommended.add(p);
        } else {
          others.add(p);
        }
      }
      return (recommended: recommended, others: others);
    },
    orElse: () => (recommended: const [], others: const []),
  );
});
