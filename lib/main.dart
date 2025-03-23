import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/navigation/bottom_navigation_page.dart';
import 'login_register_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: const String.fromEnvironment('SUPABASE_URL',
        defaultValue: 'https://nlkvnsbtrlcwwjznxhcl.supabase.co'),
    anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY',
        defaultValue:
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5sa3Zuc2J0cmxjd3dqem54aGNsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzk0MjMyNzEsImV4cCI6MjA1NDk5OTI3MX0.EHvnCp7c4xpEWIiMOsTlA29UBG3AdhyALuJhj_Bg93E'),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      home: const AuthHandler(),
    );
  }
}

class AuthHandler extends StatefulWidget {
  const AuthHandler({Key? key}) : super(key: key);

  @override
  State<AuthHandler> createState() => _AuthHandlerState();
}

class _AuthHandlerState extends State<AuthHandler> {
  @override
  void initState() {
    super.initState();

    // Escuchar cambios de sesión en Supabase
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      setState(() {}); // Redibuja la UI cuando la sesión cambia
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;

    return session != null
        ? const BottomNavigationPage()
        : const LoginRegisterApp();
  }
}
