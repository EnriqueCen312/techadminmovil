import 'dart:math';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class email_service{

  email_service();

  int code = 0;

  bool compararCodigos(int codigo){
    return codigo == code;
  }

  Future<bool> sendEmail(String recipientEmail) async {
  try {
    String? username = dotenv.env['EMAIL_USERNAME']!;
    String? password = dotenv.env['EMAIL_PASSWORD']!;
    
    int code = _generateCode();
    print('el código es: $code');

    final smtpServer = gmail(username, password);

    final message = Message()
      ..from = Address(username, 'Tech Admin móvil')
      ..recipients.add(recipientEmail)
      ..subject = 'Confirmación de cuenta'
      ..text = 'Tu código de verificación es: ${code}';

    
      final sendReport = await send(message, smtpServer);
      print('Correo enviado: $sendReport');
      return true;
    } catch (e) {
      print('Error al enviar el correo: $e');
      return false;
    }
  }

  static int _generateCode(){
    final random = Random.secure();
    return 10000 + random.nextInt(90000);
  }

}

