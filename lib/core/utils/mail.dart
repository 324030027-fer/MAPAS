import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Abre un correo nuevo en **Gmail** ya escrito.
///
/// - Web y escritorio: la ventana de redactar de Gmail en el navegador (no el
///   cliente predeterminado del sistema, que suele ser Outlook). Con
///   [account] se elige esa cuenta de Google (p. ej. la institucional).
/// - iPhone: la app de Gmail; si no está instalada, Gmail web.
/// - Android: `mailto:`, que abre Gmail (la app de correo del sistema).
///
/// Devuelve false si no se pudo abrir nada.
Future<bool> openGmailCompose({
  required String to,
  String subject = '',
  String body = '',
  String? account,
}) async {
  final web = Uri.https('mail.google.com', '/mail/', {
    'view': 'cm',
    'fs': '1',
    'to': to,
    if (subject.isNotEmpty) 'su': subject,
    if (body.isNotEmpty) 'body': body,
    if (account != null && account.isNotEmpty) 'authuser': account,
  });

  Future<bool> tryLaunch(Uri uri, LaunchMode mode) async {
    try {
      return await launchUrl(uri, mode: mode, webOnlyWindowName: '_blank');
    } catch (_) {
      return false;
    }
  }

  if (kIsWeb) return tryLaunch(web, LaunchMode.platformDefault);

  switch (defaultTargetPlatform) {
    case TargetPlatform.iOS:
      final app = Uri.parse('googlegmail:///co?to=${Uri.encodeComponent(to)}'
          '&subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}');
      if (await tryLaunch(app, LaunchMode.externalApplication)) return true;
      return tryLaunch(web, LaunchMode.externalApplication);
    case TargetPlatform.android:
      // mailto necesita %20 en lugar de "+", por eso se arma a mano.
      final mailto = Uri(
        scheme: 'mailto',
        path: to,
        query: 'subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}',
      );
      if (await tryLaunch(mailto, LaunchMode.externalApplication)) return true;
      return tryLaunch(web, LaunchMode.externalApplication);
    default:
      return tryLaunch(web, LaunchMode.externalApplication);
  }
}
