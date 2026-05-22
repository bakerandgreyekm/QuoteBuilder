import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'sheets_service_provider.dart';

final employeesProvider = FutureProvider<List<String>>((ref) async {
  return ref.read(sheetsServiceProvider).getEmployees();
});
