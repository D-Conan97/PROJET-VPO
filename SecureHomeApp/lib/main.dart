import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_screen.dart';
import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://qudgbgkonlrpaseinegi.supabase.co',
    anonKey: 'sb_publishable_WJRUyh8nLyWNnjLyaN-b0g_zZtL2ms3',
  );

  runApp(const ProviderScope(child: const SecureHomeApp()));
}

class SecureHomeApp extends StatelessWidget {
  const SecureHomeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SecureHome',
      theme: AppTheme.light,
      home: const HomeScreen(),
    );
  }
}
