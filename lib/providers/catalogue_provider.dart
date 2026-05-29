import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import 'sheets_service_provider.dart';

final systemTypeTagsProvider = FutureProvider<Map<String, List<String>>>((ref) {
  return ref.read(sheetsServiceProvider).getSystemTypeTags();
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

final catalogueProvider =
    AsyncNotifierProvider<CatalogueNotifier, List<Product>>(
        CatalogueNotifier.new);

final categoriesProvider = Provider<List<String>>((ref) {
  return ref.watch(catalogueProvider).maybeWhen(
    data: (list) => list.map((p) => p.category).toSet().toList()..sort(),
    orElse: () => [],
  );
});

final productsByCategoryProvider =
    Provider.family<List<Product>, String>((ref, category) {
  return ref.watch(catalogueProvider).maybeWhen(
    data: (list) => list.where((p) => p.category == category).toList(),
    orElse: () => [],
  );
});
