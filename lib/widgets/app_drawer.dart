import 'package:flutter/material.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:login_register_app/connection/auth/AuthController.dart';
import 'package:login_register_app/screens/login_screen.dart';
import 'package:login_register_app/utils/helpers/snackbar_helper.dart';
import 'package:login_register_app/login_register_app.dart';

class AppDrawer extends StatelessWidget {
  final VoidCallback? onSettingsTap;
  final VoidCallback? onLogoutSuccess;
  final Color backgroundColor;

  const AppDrawer({
    Key? key,
    this.onSettingsTap,
    this.onLogoutSuccess,
    this.backgroundColor = const Color(0xFF1A237E), // Color azul por defecto
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.7,
      height: MediaQuery.of(context).size.height,
      child: Drawer(
        child: Container(
          color: backgroundColor,
          child: Column(
            children: [
              SizedBox(
                height: 120,
                width: double.infinity,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Tech',
                              style: TextStyle(
                                color: Colors.orange.shade500,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              'Administrator',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Divider(color: Colors.white.withOpacity(0.3)),
              ListTile(
                leading: const Icon(Icons.settings, color: Colors.white),
                title: const Text('Configuración',
                    style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  // Aquí iría la lógica para la configuración
                },
              ),
              const Expanded(child: SizedBox()), // Espacio flexible
              Divider(color: Colors.white.withOpacity(0.3)),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.white),
                title: const Text('Cerrar Sesión',
                    style: TextStyle(color: Colors.white)),
                onTap: () async {
                  try {
                    final logOut = AuthController();
                    bool success = await logOut.logout();

                    if (success && context.mounted) {
                      Phoenix.rebirth(context);
                      // Navegar a la pantalla de login
                      /*Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                            builder: (context) => const LoginRegisterApp()),
                        (route) => false,
                      );*/
                    }
                  } catch (e) {
                    if (context.mounted) {
                      SnackbarHelper.showSnackBar("Error al cerrar sesión: $e");
                    }
                  }
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
