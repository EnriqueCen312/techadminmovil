import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_register_app.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/navigation/bottom_navigation_page.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import '../utils/helpers/navigation_helper.dart';
import '../values/app_routes.dart';
import '/screens/login_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    await dotenv.load(fileName: ".env");

    print(dotenv.env);    

    if (dotenv.env.isEmpty) {
      print("dotenv.env está vacío");
    } else {
      print("dotenv.env cargado correctamente: ${dotenv.env}");
    }

    // Inicializa Supabase
    await Supabase.initialize(
      url: const String.fromEnvironment('SUPABASE_URL', 
          defaultValue: 'https://nlkvnsbtrlcwwjznxhcl.supabase.co'),
      anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY',
          defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5sa3Zuc2J0cmxjd3dqem54aGNsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzk0MjMyNzEsImV4cCI6MjA1NDk5OTI3MX0.EHvnCp7c4xpEWIiMOsTlA29UBG3AdhyALuJhj_Bg93E'),
    );

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarIconBrightness: Brightness.light,
      ),
    );

    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    // Verificar si hay una sesión guardada
    final prefs = await SharedPreferences.getInstance();
    final String? user = prefs.getString('user');


    Widget initialScreen = (user != null) ? const BottomNavigationPage() : const LoginRegisterApp();


    runApp(Phoenix(child: MyApp(initialScreen: initialScreen)));
  } catch (error) {
    print('Error during initialization: $error');
  }
}

class MyApp extends StatelessWidget {
  final Widget initialScreen;

  const MyApp({Key? key, required this.initialScreen}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: initialScreen,
    );
  }
}