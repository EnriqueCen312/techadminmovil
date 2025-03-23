import 'package:flutter/material.dart';

class EmailConfirmationScreen extends StatefulWidget {
  const EmailConfirmationScreen({super.key});

  @override
  State<EmailConfirmationScreen> createState() =>
      _EmailConfirmationScreenState();
}

class _EmailConfirmationScreenState extends State<EmailConfirmationScreen> {
  final TextEditingController _codeController = TextEditingController();

  void _verifyCode() {
    String code = _codeController.text;
    if (code.length == 5) {
      debugPrint("Código ingresado: $code");
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("El código debe tener 5 dígitos")),
      );
    }
  }

  void _resendCode() {
    // Aquí podrías implementar el reenvío del código
    debugPrint("Reenviar código");
  }

  @override
  Widget build(BuildContext context) {
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
