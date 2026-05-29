import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/project.dart';
import 'sheets_service_provider.dart';

class ProjectsNotifier extends AsyncNotifier<List<Project>> {
  @override
  Future<List<Project>> build() async {
    final raw = await ref.read(sheetsServiceProvider).getProjects();
    return raw.map((m) => Project.fromMap(m)).toList();
  }

  Future<String> addProject(
      String name, String clientName, String location, String worker) async {
    final refNumber = await ref.read(sheetsServiceProvider).createProject(
          projectName: name,
          clientName: clientName,
          location: location,
          worker: worker,
        );
    final newProject = Project(
      id: refNumber,
      refNumber: refNumber,
      name: name,
      clientName: clientName,
      location: location,
      createdAt: DateTime.now(),
    );
    state = AsyncData([...state.value ?? [], newProject]);
    return refNumber;
  }

  Future<void> updateProject({
    required String refNumber,
    required String name,
    required String clientName,
    required String location,
  }) async {
    await ref.read(sheetsServiceProvider).updateProject(
          refNumber: refNumber,
          projectName: name,
          clientName: clientName,
          location: location,
        );
    final current = state.value ?? [];
    state = AsyncData(current
        .map((p) => p.id == refNumber
            ? p.copyWith(name: name, clientName: clientName, location: location)
            : p)
        .toList());
  }

  Future<void> deleteProject(String refNumber) async {
    await ref.read(sheetsServiceProvider).deleteProject(refNumber: refNumber);
    final current = state.value ?? [];
    state = AsyncData(current.where((p) => p.id != refNumber).toList());
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final raw = await ref.read(sheetsServiceProvider).getProjects();
      return raw.map((m) => Project.fromMap(m)).toList();
    });
  }
}

final projectsProvider =
    AsyncNotifierProvider<ProjectsNotifier, List<Project>>(
        ProjectsNotifier.new);
