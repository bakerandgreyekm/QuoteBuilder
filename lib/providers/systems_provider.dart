import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/project_system.dart';
import 'sheets_service_provider.dart';

class SystemsNotifier extends AsyncNotifier<List<ProjectSystem>> {
  @override
  Future<List<ProjectSystem>> build() async => [];

  Future<void> loadForProject(String refNumber) async {
    final types = await ref.read(sheetsServiceProvider).getSystems(refNumber);
    final current = state.value ?? [];
    final currentTypes = current
        .where((s) => s.projectId == refNumber)
        .map((s) => s.systemType)
        .toSet();
    final toAdd = types
        .where((t) => !currentTypes.contains(t))
        .map((t) => ProjectSystem(projectId: refNumber, systemType: t))
        .toList();
    if (toAdd.isEmpty) return;
    state = AsyncData([...current, ...toAdd]);
  }

  Future<void> addSystem(String refNumber, String systemType) async {
    final existing = state.value ?? [];
    if (existing.any((s) => s.projectId == refNumber && s.systemType == systemType)) return;
    // optimistic update before API call
    state = AsyncData([
      ...existing,
      ProjectSystem(projectId: refNumber, systemType: systemType),
    ]);
    await ref
        .read(sheetsServiceProvider)
        .addSystem(refNumber: refNumber, systemType: systemType);
  }

  Future<void> removeSystem(String refNumber, String systemType) async {
    final existing = state.value ?? [];
    // optimistic update before API call
    state = AsyncData(existing
        .where((s) => !(s.projectId == refNumber && s.systemType == systemType))
        .toList());
    await ref
        .read(sheetsServiceProvider)
        .removeSystem(refNumber: refNumber, systemType: systemType);
  }
}

final systemsProvider =
    AsyncNotifierProvider<SystemsNotifier, List<ProjectSystem>>(
        SystemsNotifier.new);
