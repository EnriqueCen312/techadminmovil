import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:login_register_app/utils/helpers/snackbar_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../connection/auth/AuthController.dart';

class EmailConfirmationScreen extends StatefulWidget {
  const EmailConfirmationScreen({super.key});

  @override
  State<EmailConfirmationScreen> createState() =>
      _EmailConfirmationScreenState();
}

class _EmailConfirmationScreenState extends State<EmailConfirmationScreen> {
  final TextEditingController _codeController = TextEditingController();

  int code = 0;
  String email = '';
  String password = '';
  String name = '';
  bool isLoading = true;

  Future<void> _loadRegistrationData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final String? jsonData = prefs.getString('pendingRegistration');

      if (jsonData == null || jsonData.isEmpty) {
        print('No hay datos de registro guardados');
        return;
      }
      final Map<String, dynamic> data = json.decode(jsonData);

      email = data['email'] ?? email;
      name = data['name'] ?? name;
      password = data['password'] ?? password;
      code = data['code'] ?? code;

      print('Datos cargados correctamente para: $email');

      // Si estás en un StatefulWidget y necesitas actualizar la UI
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('Error al cargar datos de registro: $e');
    }
  }

  void _verifyCode() {
    String enteredCode = _codeController.text;

    // Verificar longitud del código (tu validación original)
    if (enteredCode.length != 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("El código debe tener 5 dígitos")),
      );
      return; // Salir del método si la longitud no es correcta
    }

    debugPrint("Código ingresado: $enteredCode");

    // Convertir a entero para comparar con el código almacenado
    final int? parsedCode = int.tryParse(enteredCode);

    // Verificar si el código coincide
    if (parsedCode != null && parsedCode == code) {
      // Código correcto
      _handleCorrectCode();
    } else {
      // Código incorrecto
      _handleIncorrectCode();
    }
  }

  Future<void> _handleCorrectCode() async {
    // Mostrar mensaje de éxito
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('¡Código verificado correctamente!'),
        backgroundColor: Colors.green,
      ),
    );
    //regista el usuario
    final authController = AuthController();
    final response = await authController.signUp(name, email, password);
    if (response['success']) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('pendingRegistration');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message'] ?? 'Registro exitoso'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message'] ?? 'Ha ocurrido un error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleIncorrectCode() {
    // Mostrar mensaje de error
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Código incorrecto. Inténtalo nuevamente.'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _resendCode() {
    // Aquí podrías implementar el reenvío del código
    debugPrint("Reenviar código");
  }

  @override
  void initState() {
    super.initState();
    // Cargar datos automáticamente al iniciar la pantalla
    _loadRegistrationData().then((_) {
      // Cuando termine de cargar, actualizar estado
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text("Confirmación de Correo")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Ingresa el código de 5 dígitos que enviamos a tu correo",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              maxLength: 5,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "12345",
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _verifyCode,
              child: const Text("Verificar"),
            ),
            TextButton(
              onPressed: _resendCode,
              child: const Text("Reenviar código"),
            ),
          ],
        ),
      ),
    );
  }
}
