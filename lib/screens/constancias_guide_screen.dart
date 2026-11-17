import 'dart:io' show Directory, File, Platform, Process;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/theme/app_colors.dart';
import '../widgets/glass.dart';

/// Guía para solicitar constancias y cartas de presentación.
///
/// Es solo una guía: NO guarda nada. Los datos que el alumno escribe para
/// armar el correo viven en memoria mientras la pantalla está abierta.
class ConstanciasGuideScreen extends StatefulWidget {
  const ConstanciasGuideScreen({super.key});

  static const sitoUrl = 'http://sito.upjr.edu.mx/';
  static const email = 'auxiliar_escolares@upjr.edu.mx';
  static const subject = 'Solicitud de Constancia';
  static const pdfAsset = 'assets/docs/proceso_constancias_2026.pdf';
  static const pdfName = 'Proceso para solicitar constancias 2026.pdf';

  static const tipos = [
    'Con promedio general',
    'Con promedio cuatrimestral',
    'Con número de seguro social',
    'Con Kardex académico',
    'Con periodo vacacional',
    'De egresado',
    'Sencilla',
    'Carta de presentación',
  ];

  @override
  State<ConstanciasGuideScreen> createState() => _ConstanciasGuideScreenState();
}

class _ConstanciasGuideScreenState extends State<ConstanciasGuideScreen> {
  final _form = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _grado = TextEditingController();
  final _grupo = TextEditingController();
  final _destinatario = TextEditingController();
  final _cargo = TextEditingController();
  final _empresa = TextEditingController();
  String? _tipo;

  bool get _esCarta => _tipo == 'Carta de presentación';

  @override
  void dispose() {
    for (final c in [_nombre, _grado, _grupo, _destinatario, _cargo, _empresa]) {
      c.dispose();
    }
    super.dispose();
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _open(Uri uri) async {
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _snack('No se pudo abrir $uri');
    }
  }

  /// Descarga/comparte el PDF oficial incluido en la app.
  Future<void> _downloadGuide() async {
    try {
      if (kIsWeb) {
        // En web los assets se sirven en /assets/<ruta>.
        await _open(Uri.base.resolve('assets/${ConstanciasGuideScreen.pdfAsset}'));
        return;
      }
      final data = await rootBundle.load(ConstanciasGuideScreen.pdfAsset);
      final bytes = data.buffer.asUint8List();
      if (Platform.isAndroid || Platform.isIOS) {
        // Hoja de compartir: "Guardar en Archivos", Drive, WhatsApp…
        await SharePlus.instance.share(ShareParams(
          files: [XFile.fromData(bytes, mimeType: 'application/pdf', name: ConstanciasGuideScreen.pdfName)],
          fileNameOverrides: [ConstanciasGuideScreen.pdfName],
          subject: 'Proceso para solicitar constancias',
        ));
        return;
      }
      // Escritorio: se guarda en Descargas y se abre.
      final home = Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'] ?? Directory.systemTemp.path;
      final dir = Directory('$home${Platform.pathSeparator}Downloads');
      final file = File('${(await dir.exists()) ? dir.path : Directory.systemTemp.path}'
          '${Platform.pathSeparator}${ConstanciasGuideScreen.pdfName}');
      await file.writeAsBytes(bytes);
      if (Platform.isWindows) {
        await Process.run('explorer', [file.path]);
      } else {
        await launchUrl(Uri.file(file.path));
      }
      if (mounted) _snack('Guía guardada en ${file.path}');
    } catch (e) {
      _snack('No se pudo descargar la guía');
    }
  }

  void _copyEmail() {
    Clipboard.setData(const ClipboardData(text: ConstanciasGuideScreen.email));
    _snack('Correo copiado');
  }

  String _body() {
    final b = StringBuffer()
      ..writeln('Buen día.')
      ..writeln()
      ..writeln(_esCarta
          ? 'Solicito una carta de presentación.'
          : 'Solicito una constancia de estudios: ${_tipo!.toLowerCase()}.')
      ..writeln()
      ..writeln('Nombre completo: ${_nombre.text.trim()}')
      ..writeln('Grado: ${_grado.text.trim()}')
      ..writeln('Grupo: ${_grupo.text.trim()}');
    if (_esCarta) {
      b
        ..writeln()
        ..writeln('Datos para la carta de presentación:')
        ..writeln('Dirigida a: ${_destinatario.text.trim()}')
        ..writeln('Cargo: ${_cargo.text.trim()}')
        ..writeln('Empresa: ${_empresa.text.trim()}');
    }
    b
      ..writeln()
      ..writeln('Adjunto la foto de mi comprobante de pago con mi nombre, carrera y matrícula.')
      ..writeln()
      ..writeln('Gracias.');
    return b.toString();
  }

  Future<void> _sendEmail() async {
    if (!_form.currentState!.validate()) return;
    final uri = Uri(
      scheme: 'mailto',
      path: ConstanciasGuideScreen.email,
      // mailto necesita %20 en lugar de "+", por eso se arma a mano.
      query: 'subject=${Uri.encodeComponent(ConstanciasGuideScreen.subject)}'
          '&body=${Uri.encodeComponent(_body())}',
    );
    await _open(uri);
  }

  /// Cuándo estaría lista si se envía ahora.
  String _deliveryNow() {
    final now = DateTime.now();
    return now.hour < 12
        ? 'Si lo envías ahora (antes de mediodía), tu constancia estará lista hoy después de las 13:30.'
        : 'Si lo envías ahora (después de mediodía), tu constancia estará lista mañana.';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? Colors.white : AppColors.textPrimaryLight;
    final fg2 = isDark ? Colors.white70 : AppColors.textSecondaryLight;

    Widget step(int n, String title, List<Widget> children) => GlassCard(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: AppColors.primary,
                    child: Text('$n', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(title, style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 15))),
                ]),
                const SizedBox(height: 10),
                ...children,
              ],
            ),
          ),
        );

    Text p(String t) => Text(t, style: TextStyle(color: fg2, height: 1.4));
    Widget bullet(String t) => Padding(
          padding: const EdgeInsets.only(left: 6, top: 2),
          child: Text('•  $t', style: TextStyle(color: fg2)),
        );

    InputDecoration deco(String label) => InputDecoration(labelText: label, isDense: true, border: const OutlineInputBorder());
    String? req(String? v) => (v == null || v.trim().isEmpty) ? 'Obligatorio' : null;

    return GlassScaffold(
      appBar: AppBar(
        title: const Text('Solicitar constancia'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(tooltip: 'Descargar guía (PDF)', icon: const Icon(Icons.download_rounded), onPressed: _downloadGuide),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            Text('Constancias y cartas de presentación',
                style: TextStyle(color: fg, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            p('Sigue estos pasos. Esta guía no guarda ningún dato.'),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _downloadGuide,
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('Descargar la guía oficial (PDF)'),
            ),
            const SizedBox(height: 16),

            step(1, 'Genera tu referencia de pago en SITO', [
              p('Entra con tu usuario y contraseña de siempre y ve a:'),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  for (final (i, s) in ['Alumnos', 'Consultas', 'Referencias de pago', 'CONSTANCIA ESTUDIOS'].indexed) ...[
                    if (i > 0) Icon(Icons.chevron_right, size: 16, color: fg2),
                    Chip(label: Text(s, style: const TextStyle(fontSize: 12)), visualDensity: VisualDensity.compact),
                  ],
                ],
              ),
              p('Elige el banco de tu preferencia o paga en línea.'),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: () => _open(Uri.parse(ConstanciasGuideScreen.sitoUrl)),
                icon: const Icon(Icons.open_in_new),
                label: const Text('Abrir SITO y obtener mi referencia'),
              ),
            ]),

            step(2, 'Paga', [
              p('Imprime tu referencia y paga en el banco que elegiste. '
                  'Si pagas en línea, guarda el comprobante que se genera al final.'),
            ]),

            step(3, 'Anota tus datos en el comprobante', [
              bullet('Tu nombre completo'),
              bullet('Carrera'),
              bullet('Matrícula'),
            ]),

            step(4, 'Envía el correo desde tu correo institucional', [
              p('Toma una foto (legible) o escanea el comprobante. Llena esto y la app '
                  'te abre el correo ya escrito; solo adjunta la foto y envíalo.'),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: SelectableText(ConstanciasGuideScreen.email,
                      style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600)),
                ),
                IconButton(tooltip: 'Copiar correo', icon: const Icon(Icons.copy, size: 18), onPressed: _copyEmail),
              ]),
              Text('Asunto: ${ConstanciasGuideScreen.subject}', style: TextStyle(color: fg2, fontStyle: FontStyle.italic)),
              const SizedBox(height: 12),
              Form(
                key: _form,
                child: Column(children: [
                  TextFormField(controller: _nombre, decoration: deco('Nombre completo'), validator: req),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(child: TextFormField(controller: _grado, decoration: deco('Grado'), validator: req)),
                    const SizedBox(width: 10),
                    Expanded(child: TextFormField(controller: _grupo, decoration: deco('Grupo'), validator: req)),
                  ]),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: _tipo,
                    isExpanded: true,
                    decoration: deco('Tipo de constancia'),
                    items: [
                      for (final t in ConstanciasGuideScreen.tipos) DropdownMenuItem(value: t, child: Text(t)),
                    ],
                    onChanged: (v) => setState(() => _tipo = v),
                    validator: (v) => v == null ? 'Elige un tipo' : null,
                  ),
                  if (_esCarta) ...[
                    const SizedBox(height: 10),
                    Text('Sin estos datos no se emite la carta:',
                        style: TextStyle(color: AppColors.highlight, fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    TextFormField(controller: _destinatario, decoration: deco('Nombre completo de a quién va dirigida'), validator: req),
                    const SizedBox(height: 10),
                    TextFormField(controller: _cargo, decoration: deco('Cargo'), validator: req),
                    const SizedBox(height: 10),
                    TextFormField(controller: _empresa, decoration: deco('Nombre completo de la empresa'), validator: req),
                  ],
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _sendEmail,
                      icon: const Icon(Icons.email_outlined),
                      label: const Text('Redactar correo'),
                    ),
                  ),
                ]),
              ),
            ]),

            step(5, 'Espera la notificación', [
              p('Te avisan a tu correo institucional cuando tu constancia está lista para entregarse.'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.highlight.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(children: [
                  const Icon(Icons.schedule, color: AppColors.highlight),
                  const SizedBox(width: 10),
                  Expanded(child: Text(_deliveryNow(), style: TextStyle(color: fg))),
                ]),
              ),
              const SizedBox(height: 8),
              bullet('Pago enviado antes de mediodía: se entrega después de las 13:30.'),
              bullet('Después de mediodía: se entrega al día siguiente.'),
            ]),
          ],
        ),
      ),
    );
  }
}
