import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import 'sheets_service_provider.dart';

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
