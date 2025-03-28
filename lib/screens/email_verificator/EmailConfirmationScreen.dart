import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:login_register_app/connection/email_service/email_service.dart';
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

      debugPrint('Datos cargados correctamente para: $email');

      // Si estás en un StatefulWidget y necesitas actualizar la UI
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error al cargar datos de registro: $e');
    }
  }

  void _verifyCode() {
    String enteredCode = _codeController.text;

    // Verificar longitud del código
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
  try {
    // Mostrar mensaje de éxito
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Código verificado correctamente!'),
          backgroundColor: Colors.green,
        ),
      );
    }

    // Registrar el usuario
    final authController = AuthController();
    final response = await authController.signUp(name, email, password);

    if (response['success']) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('pendingRegistration');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Registro exitoso'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Ha ocurrido un error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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

  void _resendCode() async{
    try{

      final emailService = EmailService();
      final result = await emailService.reSendEmail(email, code);
      debugPrint("Reenviar código");
      
      if(result['success']){
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Código reenviado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }else{
        ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo reenviar el código'),
          backgroundColor: Colors.red,
        ),
      );
      }

    }catch(e){
      debugPrint("Error al reenviar el código: $e");
    }
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Color(0xFF084F93),
              ),
              SizedBox(height: 20),
              Text(
                "Cargando...",
                style: TextStyle(
                  color: Color(0xFF084F93),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Confirmación de Correo",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: const Color(0xFF084F93),
        elevation: 0,
        centerTitle: true,
      ),
      backgroundColor: Colors.white,
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFECF0F1),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(25.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      color: const Color(0xFF084F93).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.mark_email_read,
                      size: 70,
                      color: Color(0xFF084F93),
                    ),
                  ),
                  const SizedBox(height: 25),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          "Verificación de Email",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF084F93),
                          ),
                        ),
                        const SizedBox(height: 15),
                        const Text(
                          "Hemos enviado un código de 5 dígitos a:",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          email,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF084F93),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 5),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.grey.shade100,
                          ),
                          child: TextField(
                            controller: _codeController,
                            keyboardType: TextInputType.number,
                            maxLength: 5,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 26,
                              letterSpacing: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF084F93),
                            ),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: "12345",
                              hintStyle: TextStyle(
                                color: Colors.grey.shade400,
                                letterSpacing: 5,
                              ),
                              counterText: "",
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _verifyCode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF084F93),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: const Text(
                        "Verificar Código",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "¿No recibiste el código? ",
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 15,
                        ),
                      ),
                      TextButton(
                        onPressed: _resendCode,
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF084F93),
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 35),
                        ),
                        child: const Text(
                          "Reenviar",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
