import 'package:flutter/material.dart';

import 'models/models.dart';
import 'api/api_client.dart';
import 'screens/auth_screen.dart';
import 'screens/dashboard_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final api = ApiClient();
  await api.restoreSession();
  runApp(App(api: api));
}

class App extends StatelessWidget {
  const App({super.key, required this.api});

  final ApiClient api;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4F46E5)),
        scaffoldBackgroundColor: const Color(0xFFF1F5F9),
      ),
      home: api.isAuthenticated ? DashboardScreen(api: api) : AuthScreen(api: api),
    );
  }
}
