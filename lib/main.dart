import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'router.dart';
import 'theme.dart';
import 'providers/worker_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  final settings = await Hive.openBox<String>('settings');
  final savedWorker = settings.get('workerName') ?? 'Field Worker';

  runApp(ProviderScope(
    overrides: [
      workerNameProvider.overrideWith((ref) => savedWorker),
    ],
    observers: [_SettingsPersistObserver(settings)],
    child: const QuoteBuilderApp(),
  ));
}

class _SettingsPersistObserver extends ProviderObserver {
  final Box<String> _box;
  _SettingsPersistObserver(this._box);

  @override
  void didUpdateProvider(
    ProviderBase<Object?> provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    if (provider == workerNameProvider && newValue is String) {
      _box.put('workerName', newValue);
    }
  }
}

class QuoteBuilderApp extends StatelessWidget {
  const QuoteBuilderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'QuoteBuilder',
      theme: buildAppTheme(),
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
