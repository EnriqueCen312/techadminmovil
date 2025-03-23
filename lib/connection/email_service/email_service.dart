import 'dart:math';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EmailService {
  EmailService();

  int code = 0;

  bool compararCodigos(int codigo) {
    return codigo == code;
  }

  bool isUserRegistered(String email) {
    // Simulamos que el usuario ya está registrado
    return false;
  }

  Future<Map<String, dynamic>> sendEmail(String recipientEmail) async {
    try {
      // Verificamos que las variables de entorno existan
      String? username = dotenv.env['EMAIL_USERNAME'];
      String? password = dotenv.env['EMAIL_PASSWORD'];

      if (username == null || password == null) {
        return {'success': false, 'message': 'Error interno'};
      }

      code = _generateCode();
      // Using instance variable instead of local variable
      _logInfo('El código de verificación es: $code');

      final smtpServer = gmail(username, password);

      final message = Message()
        ..from = Address(username, 'Tech Admin móvil')
        ..recipients.add(recipientEmail)
        ..subject = 'Confirmación de cuenta'
        ..text = 'Tu código de verificación es: $code'
        ..html = '''
          <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #ddd; border-radius: 5px;">
            <h2 style="color: #4a4a4a;">Confirmación de tu cuenta</h2>
            <p>Gracias por registrarte. Por favor utiliza el siguiente código para verificar tu cuenta:</p>
            <div style="background-color: #f5f5f5; padding: 10px; text-align: center; font-size: 24px; font-weight: bold; letter-spacing: 5px; margin: 20px 0;">
              $code
            </div>
            <p>Este código expirará en 5 minutos por razones de seguridad.</p>
            <p>Si no has solicitado este código, puedes ignorar este mensaje.</p>
            <p style="font-size: 12px; color: #777; margin-top: 20px;">Este es un correo automático, por favor no respondas a este mensaje.</p>
          </div>
        ''';

      final sendReport = await send(message, smtpServer);
      _logInfo('Correo enviado exitosamente: ${sendReport.toString()}');

      return {
        'success': true,
        'message': 'Código de verificación enviado con éxito a $recipientEmail'
      };
    } catch (e) {
      _logError('Error al enviar el correo: $e');

      // Personalizar el mensaje de error según el tipo de excepción
      String errorMessage = 'No se pudo enviar el correo de verificación';

      if (e.toString().contains('Invalid address')) {
        errorMessage =
            'La dirección de correo $recipientEmail parece ser inválida';
      } else if (e.toString().contains('Authentication failed')) {
        errorMessage = 'Error de autenticación con el servidor de correo';
      } else if (e.toString().contains('Connection timed out')) {
        errorMessage =
            'Tiempo de espera agotado al conectar con el servidor de correo';
      }

      return {'success': false, 'message': errorMessage};
    }
  }

  int _generateCode() {
    final random = Random.secure();
    return 10000 + random.nextInt(90000);
  }

  // Simple logging methods that could be replaced with a proper logging framework
  void _logInfo(String message) {
    // Replace with proper logging in production
    // ignore: avoid_print
    print(message);
  }

  void _logError(String message) {
    // Replace with proper logging in production
    // ignore: avoid_print
    print(message);
  }
}
