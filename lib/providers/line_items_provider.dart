import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/line_item.dart';
import 'sheets_service_provider.dart';
import 'worker_provider.dart';

class LineItemsNotifier extends AsyncNotifier<List<LineItem>> {
  @override
  Future<List<LineItem>> build() async => [];

  Future<void> loadForProject(String refNumber) async {
    final raw = await ref.read(sheetsServiceProvider).getLineItems(refNumber);
    final fetched = raw
        .where((m) =>
            !(m['ID']?.toString() ?? m['id']?.toString() ?? '')
                .startsWith('SYSTEM_PLACEHOLDER_'))
        .map((m) => LineItem.fromMap(m, refNumber))
        .toList();
    final current = state.value ?? [];
    final fetchedIds = fetched.map((i) => i.id).toSet();
    final localExtra = current
        .where((i) =>
            i.projectId == refNumber &&
            i.id.isNotEmpty &&
            !fetchedIds.contains(i.id))
        .toList();
    final otherProjects = current.where((i) => i.projectId != refNumber).toList();
    state = AsyncData([...otherProjects, ...fetched, ...localExtra]);
  }

  Future<void> addItem(LineItem item) async {
    final worker = ref.read(workerNameProvider);
    final id = await ref.read(sheetsServiceProvider).addLineItem(
          refNumber: item.projectId,
          systemType: item.systemType,
          category: item.category,
          productName: item.productName,
          brand: item.brand,
          unit: item.unit,
          quantity: item.quantity,
          rate: item.rate,
          noteText: item.noteText,
          worker: worker,
          area: item.area,
        );
    final itemWithId = item.copyWith(id: id);
    final existing = state.value ?? [];
    state = AsyncData([...existing, itemWithId]);
  }

  Future<void> updateItem({
    required String refNumber,
    required String itemId,
    required int quantity,
    required String noteText,
    String? area,
    double? rate,
  }) async {
    await ref.read(sheetsServiceProvider).updateLineItem(
          refNumber: refNumber,
          itemId: itemId,
          quantity: quantity,
          noteText: noteText,
          area: area,
          rate: rate,
        );
    final existing = state.value ?? [];
    state = AsyncData(existing.map((i) {
      if (i.id != itemId) return i;
      return LineItem(
        id: i.id,
        projectId: i.projectId,
        systemType: i.systemType,
        category: i.category,
        productName: i.productName,
        brand: i.brand,
        unit: i.unit,
        quantity: quantity,
        rate: rate ?? i.rate,
        noteText: noteText,
        area: area,
      );
    }).toList());
  }

  Future<void> deleteItem(String refNumber, String itemId) async {
    await ref
        .read(sheetsServiceProvider)
        .deleteLineItem(refNumber: refNumber, itemId: itemId);
    final existing = state.value ?? [];
    state = AsyncData(existing.where((i) => i.id != itemId).toList());
  }
}

final lineItemsProvider =
    AsyncNotifierProvider<LineItemsNotifier, List<LineItem>>(
        LineItemsNotifier.new);
