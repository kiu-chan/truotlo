import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class EmailService {
  static Future<void> sendEmail({
    required String name,
    required String email,
    required String phone,
    required String content,
  }) async {
    String username = 'khanhk66uet@gmail.com';
    String password = 'tsds yrui jurx gkwj';

    final smtpServer = gmail(username, password);

    final message = Message()
      ..from = Address(username, 'Your Application')
      ..recipients.add('21020342@vnu.edu.vn')
      ..subject = 'New Request from $name'
      ..text = '''
A new request has been submitted:

Name: $name
Email: $email
Phone: $phone

Content:
$content
''';

    try {
      final sendReport = await send(message, smtpServer);
      print('Message sent: ' + sendReport.toString());
    } on MailerException catch (e) {
      print('Message not sent. \n' + e.toString());
      throw e;
    }
  }
}