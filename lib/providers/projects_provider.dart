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
      String name, String clientName, String location, String worker,
      {String? industry, String? tier}) async {
    final refNumber = await ref.read(sheetsServiceProvider).createProject(
          projectName: name,
          clientName: clientName,
          location: location,
          worker: worker,
          industry: industry,
          tier: tier,
        );
    final newProject = Project(
      id: refNumber,
      refNumber: refNumber,
      name: name,
      clientName: clientName,
      location: location,
      createdAt: DateTime.now(),
      industry: industry,
      tier: tier,
    );
    state = AsyncData([...state.value ?? [], newProject]);
    return refNumber;
  }

  Future<void> updateProject({
    required String refNumber,
    required String name,
    required String clientName,
    required String location,
    required String? industry,
    required String? tier,
  }) async {
    await ref.read(sheetsServiceProvider).updateProject(
          refNumber: refNumber,
          projectName: name,
          clientName: clientName,
          location: location,
          industry: industry,
          tier: tier,
        );
    final current = state.value ?? [];
    state = AsyncData(current.map((p) {
      if (p.id != refNumber) return p;
      return Project(
        id: p.id,
        refNumber: p.refNumber,
        name: name,
        clientName: clientName,
        location: location,
        createdAt: p.createdAt,
        industry: industry,
        tier: tier,
        areas: p.areas,
      );
    }).toList());
  }

  Future<void> updateAreas(String projectId, List<String> areas) async {
    await ref.read(sheetsServiceProvider).updateProjectAreas(
      refNumber: projectId,
      areas: areas,
    );
    final current = state.value ?? [];
    state = AsyncData(current.map((p) {
      if (p.id != projectId) return p;
      return Project(
        id: p.id,
        refNumber: p.refNumber,
        name: p.name,
        clientName: p.clientName,
        location: p.location,
        createdAt: p.createdAt,
        industry: p.industry,
        tier: p.tier,
        areas: areas,
      );
    }).toList());
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
