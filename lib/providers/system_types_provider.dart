import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'sheets_service_provider.dart';

class SystemTypesNotifier extends AsyncNotifier<List<String>> {
  @override
  Future<List<String>> build() async {
    return ref.read(sheetsServiceProvider).getSystemTypes();
  }
}

final systemTypesProvider =
    AsyncNotifierProvider<SystemTypesNotifier, List<String>>(
        SystemTypesNotifier.new);
