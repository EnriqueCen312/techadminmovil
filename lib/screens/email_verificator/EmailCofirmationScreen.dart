import 'package:flutter/material.dart';

class EmailConfirmationScreen extends StatefulWidget {
  @override
  _EmailConfirmationScreenState createState() => _EmailConfirmationScreenState();
}

class _EmailConfirmationScreenState extends State<EmailConfirmationScreen> {
  final TextEditingController _codeController = TextEditingController();

  void _verifyCode() {
    String code = _codeController.text;
    if (code.length == 5) {
      // Aquí podrías llamar a Supabase para verificar el código
      print("Código ingresado: $code");
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("El código debe tener 5 dígitos")),
      );
    }
  }

  void _resendCode() {
    // Aquí podrías implementar el reenvío del código
    print("Reenviar código");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Confirmación de Correo")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Ingresa el código de 5 dígitos que enviamos a tu correo",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              maxLength: 5,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: "12345",
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _verifyCode,
              child: Text("Verificar"),
            ),
            TextButton(
              onPressed: _resendCode,
              child: Text("Reenviar código"),
            ),
          ],
        ),
      ),
    );
  }
}