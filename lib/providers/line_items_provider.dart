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
    // Keep locally added items not yet reflected in the fetch (added while in-flight)
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
        );
    final itemWithId = item.copyWith(id: id);
    final existing = state.value ?? [];
    state = AsyncData([...existing, itemWithId]);
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
