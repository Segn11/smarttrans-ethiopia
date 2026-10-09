import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'navigation/router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: SmartTransApp()));
}

class SmartTransApp extends ConsumerWidget {
  const SmartTransApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    
    return MaterialApp.router(
      title: 'SmartTrans Ethiopia',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme, // Only dark theme provided as requested for modern look
      routerConfig: router,
    );
  }
}
