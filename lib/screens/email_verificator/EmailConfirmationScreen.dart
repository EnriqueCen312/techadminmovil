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

    // Verificar longitud del código
    if (enteredCode.length != 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("El código debe tener 5 dígitos"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    debugPrint("Código ingresado: $enteredCode");

    // Si no tenemos datos de registro, mostrar error
    if (email.isEmpty || password.isEmpty || name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No hay datos de registro. Vuelve a intentar el proceso."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

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
      // Mostrar mensaje de éxito al verificar el código
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Código verificado correctamente!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ),
      );
      
      // Mostrar indicador de carga
      setState(() {
        isLoading = true;
      });
      
      // Registra el usuario
      final authController = AuthController();
      final response = await authController.signUp(name, email, password);
      
      // Importante: limpiar los datos de registro pendientes antes de navegar
      if (response['success']) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('pendingRegistration');
      }
      
      // Verificar que el contexto aún existe
      if (!mounted) return;
      
      // Importante: desactivar el estado de carga antes de mostrar mensajes
      setState(() {
        isLoading = false;
      });
      
      if (response['success']) {
        // Mostrar mensaje de éxito brevemente
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Registro exitoso'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
        
        // Usar una navegación más directa sin delay para evitar problemas
        Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
      } else {
        // Verificar si es un error de correo ya existente
        final message = response['message'] ?? 'Ha ocurrido un error';
        final isEmailExistsError = message.toLowerCase().contains('email') && 
                                 (message.toLowerCase().contains('exist') || 
                                  message.toLowerCase().contains('registrado') ||
                                  message.toLowerCase().contains('ya está en uso'));
        
        if (isEmailExistsError) {
          // Error específico de correo ya registrado
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Este correo electrónico ya está registrado. Intenta iniciar sesión.'),
              backgroundColor: Colors.orange,
              action: SnackBarAction(
                label: 'Iniciar sesión',
                textColor: Colors.white,
                onPressed: () {
                  // Navegar a la pantalla de inicio de sesión
                  Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                },
              ),
              duration: Duration(seconds: 6),
            ),
          );
          
          // Eliminar datos pendientes ya que no se puede registrar este correo
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('pendingRegistration');
        } else {
          // Otros errores
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Error inesperado - asegurarse de desactivar el estado de carga
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ha ocurrido un error inesperado: ${e.toString()}'),
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

  void _resendCode() {
    // Aquí podrías implementar el reenvío del código
    debugPrint("Reenviar código");
  }

  @override
  void initState() {
    super.initState();
    // Iniciar en estado de carga
    isLoading = true;
    
    // Cargar datos automáticamente al iniciar la pantalla
    _loadRegistrationData().then((_) {
      // Cuando termine de cargar, actualizar estado
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }).catchError((error) {
      // En caso de error, asegurarse de que no se quede en carga
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        
        // Mostrar mensaje de error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar datos: ${error.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Color(0xFF084F93), // Cambiado al color solicitado
              ),
              SizedBox(height: 20),
              Text(
                "Cargando...",
                style: TextStyle(
                  color: Color(0xFF084F93), // Cambiado al color solicitado
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
        backgroundColor: Color(0xFF084F93), // Cambiado al color solicitado
        elevation: 0,
        centerTitle: true,
      ),
      backgroundColor: Colors.white,
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
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
                  // Icono de email con círculo
                  Container(
                    padding: EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      color: Color(0xFF084F93).withOpacity(0.1), // Cambiado al color solicitado
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.mark_email_read,
                      size: 70,
                      color: Color(0xFF084F93), // Cambiado al color solicitado
                    ),
                  ),
                  const SizedBox(height: 25),
                  // Tarjeta principal
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          "Verificación de Email",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF084F93), // Cambiado al color solicitado
                          ),
                        ),
                        const SizedBox(height: 15),
                        Text(
                          "Hemos enviado un código de 5 dígitos a:",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          email,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF084F93), // Cambiado al color solicitado
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Campo de código
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.grey.shade100,
                          ),
                          child: TextField(
                            controller: _codeController,
                            keyboardType: TextInputType.number,
                            maxLength: 5,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 26, 
                              letterSpacing: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF084F93), // Cambiado al color solicitado
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
                  // Botón de verificación
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _verifyCode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF084F93), // Cambiado al color solicitado
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
                  // Opción de reenvío
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "¿No recibiste el código? ",
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 15,
                        ),
                      ),
                      TextButton(
                        onPressed: _resendCode,
                        style: TextButton.styleFrom(
                          foregroundColor: Color(0xFF084F93), // Cambiado al color solicitado
                          padding: EdgeInsets.zero,
                          minimumSize: Size(0, 35),
                        ),
                        child: Text(
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
