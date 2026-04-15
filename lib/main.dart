import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/welcome_screen.dart';
import 'screens/request_access_screen.dart';
import 'screens/role_selection_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/admin_upload_screen.dart';
import 'services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await Supabase.initialize(
    url: SupabaseService.supabaseUrl,
    anonKey: SupabaseService.supabaseAnonKey,
  );
  runApp(const VeltrikApp());
}

class VeltrikApp extends StatelessWidget {
  const VeltrikApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Veltrik App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.blueAccent,
        scaffoldBackgroundColor: const Color(0xFF0D0F22),
        useMaterial3: true,
      ),
      initialRoute: '/welcome',
      routes: {
        '/welcome': (context) => const WelcomeScreen(),
        '/login': (context) => const RequestAccessScreen(),
        '/role_selection': (context) => const RoleSelectionScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/admin-upload': (context) => const AdminUploadScreen(),
      },
    );
  }
}
