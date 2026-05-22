import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/sheets_service.dart';

final sheetsServiceProvider = Provider<SheetsService>((ref) => SheetsService());
