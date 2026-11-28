import 'dart:io' show Directory, File, Platform, Process;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/theme/app_colors.dart';
import '../core/utils/mail.dart';
import '../providers/auth_provider.dart';
import '../providers/private_data_provider.dart';
import '../widgets/glass.dart';
import '../widgets/responsive.dart';

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
  final _formAnchor = GlobalKey();
  final _nombre = TextEditingController();
  final _grado = TextEditingController();
  final _grupo = TextEditingController();
  final _destinatario = TextEditingController();
  final _cargo = TextEditingController();
  final _empresa = TextEditingController();
  String? _tipo;
  bool _tipoError = false;

  bool get _esCarta => _tipo == 'Carta de presentación';

  @override
  void dispose() {
    for (final c in [_nombre, _grado, _grupo, _destinatario, _cargo, _empresa]) {
      c.dispose();
    }
    super.dispose();
  }

  void _snack(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));

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
    Clipboard.setData(ClipboardData(text: _email));
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
    final okForm = _form.currentState!.validate();
    setState(() => _tipoError = _tipo == null);
    if (!okForm || _tipo == null) {
      // En el teléfono el botón está fijo abajo: lleva al formulario.
      final ctx = _formAnchor.currentContext;
      if (ctx != null) {
        await Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic);
      }
      return;
    }
    final ok = await openGmailCompose(
      to: _email,
      subject: _subject,
      body: _body(),
      account: context.read<AuthProvider>().email,
    );
    if (!ok && mounted) {
      _copyEmail();
      _snack('No se pudo abrir Gmail; copiamos el correo de Control Escolar.');
    }
  }

  // Datos editables por los admins en Firestore (guides/constancias). Si aún
  // no cargan o no existen, se usan los valores del PDF oficial 2026.
  Map<String, dynamic> get _g => context.read<PrivateDataProvider>().guide('constancias') ?? const {};
  String get _sitoUrl => _g['sitoUrl'] as String? ?? ConstanciasGuideScreen.sitoUrl;
  String get _email => _g['email'] as String? ?? ConstanciasGuideScreen.email;
  String get _subject => _g['subject'] as String? ?? ConstanciasGuideScreen.subject;
  List<String> get _tipos => (_g['tipos'] as List?)?.cast<String>() ?? ConstanciasGuideScreen.tipos;
  int get _cutoff => (_g['cutoffHour'] as num?)?.toInt() ?? 12;
  String get _ready => _g['readyTime'] as String? ?? '13:30';

  String get _cutoffLabel => _cutoff == 12 ? 'mediodía' : 'las $_cutoff:00';

  /// Cuándo estaría lista si se envía ahora.
  ({String title, String detail}) _deliveryNow() {
    final before = DateTime.now().hour < _cutoff;
    return before
        ? (title: 'Hoy después de las $_ready', detail: 'si envías antes de $_cutoffLabel')
        : (title: 'Mañana', detail: 'porque ya pasó $_cutoffLabel');
  }

  @override
  Widget build(BuildContext context) {
    context.watch<PrivateDataProvider>(); // se reconstruye si cambia la guía
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fg = dark ? Colors.white : AppColors.textPrimaryLight;
    final wide = MediaQuery.sizeOf(context).width >= 940;
    final delivery = _deliveryNow();

    final steps = _Timeline(
      steps: [
        _Step(
          icon: Icons.receipt_long_rounded,
          title: 'Genera tu referencia en SITO',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Breadcrumb(const ['Alumnos', 'Consultas', 'Referencias de pago', 'Constancia estudios']),
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                onPressed: () => _open(Uri.parse(_sitoUrl)),
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: const Text('Abrir SITO'),
              ),
            ],
          ),
        ),
        const _Step(
          icon: Icons.payments_rounded,
          title: 'Paga y anota tus datos',
          subtitle: 'En el banco o en línea. Escribe en el comprobante tu nombre, carrera y matrícula.',
        ),
        _Step(
          icon: Icons.mail_rounded,
          title: 'Envía tu solicitud',
          subtitle: wide ? 'Llena el formulario de la derecha.' : 'Llena el formulario de abajo; se abre Gmail ya escrito.',
        ),
        _Step(
          icon: Icons.inventory_2_rounded,
          title: 'Recógela en Control Escolar',
          subtitle: 'Te avisan a tu correo institucional cuando esté lista.',
          last: true,
        ),
      ],
    );

    final header = _DeliveryBanner(title: delivery.title, detail: delivery.detail);

    return GlassScaffold(
      appBar: AppBar(
        title: const Text('Solicitar constancia'),
        backgroundColor: Colors.transparent,
        foregroundColor: fg,
        // Si se abrió directo por URL no hay a dónde regresar: va al inicio.
        leading: Navigator.canPop(context)
            ? null
            : IconButton(tooltip: 'Inicio', icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.go('/')),
        actions: [
          if (wide)
            TextButton.icon(
              onPressed: _downloadGuide,
              icon: const Icon(Icons.picture_as_pdf_rounded),
              label: const Text('Guía oficial (PDF)'),
            )
          else
            IconButton(tooltip: 'Guía oficial (PDF)', icon: const Icon(Icons.picture_as_pdf_rounded), onPressed: _downloadGuide),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: wide
            ? SingleChildScrollView(
                padding: centeredListPadding(context, maxWidth: 1040, top: 8, bottom: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    header,
                    const SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 5, child: steps),
                        const SizedBox(width: 24),
                        Expanded(flex: 6, child: _formCard(dark)),
                      ],
                    ),
                  ],
                ),
              )
            // Teléfono: todo en una columna (el formulario siempre construido)
            // y el botón principal fijo abajo, siempre a la mano.
            : Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: centeredListPadding(context, horizontal: 16, top: 8, bottom: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          header,
                          const SizedBox(height: 18),
                          steps,
                          const SizedBox(height: 20),
                          _formCard(dark, showButton: false),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    decoration: BoxDecoration(
                      color: (dark ? AppColors.darkBg : AppColors.lightBg).withValues(alpha: 0.96),
                      border: Border(top: BorderSide(color: (dark ? Colors.white : Colors.black).withValues(alpha: 0.08))),
                    ),
                    child: _sendButton(),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _sendButton() => FilledButton.icon(
        onPressed: _sendEmail,
        icon: const Icon(Icons.send_rounded),
        label: const Text('Redactar en Gmail'),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.onAccent,
          minimumSize: const Size.fromHeight(52),
          textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );

  Widget _formCard(bool dark, {bool showButton = true}) {
    final fg = dark ? Colors.white : AppColors.textPrimaryLight;
    final muted = dark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    String? req(String? v) => (v == null || v.trim().isEmpty) ? 'Obligatorio' : null;
    InputDecoration deco(String label, {IconData? icon}) => InputDecoration(
          labelText: label,
          prefixIcon: icon == null ? null : Icon(icon, size: 20),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        );

    return GlassContainer(
      key: _formAnchor,
      radius: 24,
      blur: 0,
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Tus datos', style: TextStyle(color: fg, fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),
            TextFormField(
              controller: _nombre,
              decoration: deco('Nombre completo', icon: Icons.person_outline_rounded),
              textCapitalization: TextCapitalization.words,
              validator: req,
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: TextFormField(controller: _grado, decoration: deco('Grado'), validator: req)),
              const SizedBox(width: 12),
              Expanded(child: TextFormField(controller: _grupo, decoration: deco('Grupo'), validator: req)),
            ]),
            const SizedBox(height: 18),
            Text('Tipo de constancia', style: TextStyle(color: fg, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in _tipos)
                  ChoiceChip(
                    label: Text(t),
                    selected: _tipo == t,
                    showCheckmark: false,
                    onSelected: (_) => setState(() {
                      _tipo = t;
                      _tipoError = false;
                    }),
                    selectedColor: AppColors.accent,
                    labelStyle: TextStyle(
                      color: _tipo == t ? AppColors.onAccent : fg,
                      fontWeight: _tipo == t ? FontWeight.w800 : FontWeight.w500,
                      fontSize: 13,
                    ),
                    side: BorderSide(color: _tipo == t ? AppColors.accent : (dark ? Colors.white24 : Colors.black12)),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: dark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                    shape: const StadiumBorder(),
                  ),
              ],
            ),
            if (_tipoError)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('Elige un tipo', style: TextStyle(color: AppColors.danger, fontSize: 12)),
              ),
            // Carta de presentación: datos extra obligatorios.
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              child: !_esCarta
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                      padding: const EdgeInsets.only(top: 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('Datos de la carta', style: TextStyle(color: fg, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 10),
                          TextFormField(controller: _destinatario, decoration: deco('Dirigida a (nombre completo)'), validator: req),
                          const SizedBox(height: 12),
                          TextFormField(controller: _cargo, decoration: deco('Cargo'), validator: req),
                          const SizedBox(height: 12),
                          TextFormField(controller: _empresa, decoration: deco('Empresa'), validator: req),
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: 20),
            // Para quién va y qué adjuntar.
            Container(
              padding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
              decoration: BoxDecoration(
                color: dark ? Colors.white.withValues(alpha: 0.05) : AppColors.lightBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(Icons.alternate_email_rounded, size: 20, color: muted),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Para: Control Escolar', style: TextStyle(color: muted, fontSize: 11.5)),
                        Text(_email, style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 13.5)),
                      ],
                    ),
                  ),
                  IconButton(tooltip: 'Copiar correo', icon: const Icon(Icons.copy_rounded, size: 18), onPressed: _copyEmail),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.attach_file_rounded, size: 18, color: dark ? AppColors.accent : AppColors.accentOnLight),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'En Gmail adjunta la foto de tu comprobante.',
                    style: TextStyle(color: muted, fontSize: 12.5),
                  ),
                ),
              ],
            ),
            if (showButton) ...[const SizedBox(height: 16), _sendButton()],
          ],
        ),
      ),
    );
  }
}

/// Cuándo estará lista la constancia si se envía ahora.
class _DeliveryBanner extends StatelessWidget {
  const _DeliveryBanner({required this.title, required this.detail});
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: dark
              ? [AppColors.accent.withValues(alpha: 0.22), AppColors.accent.withValues(alpha: 0.08)]
              : [const Color(0xFFFFF1DA), const Color(0xFFFFF8EC)],
        ),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.schedule_rounded, color: AppColors.onAccent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Si la pides ahora, estará lista',
                  style: TextStyle(color: dark ? Colors.white70 : AppColors.textSecondaryLight, fontSize: 12.5),
                ),
                Text(
                  title,
                  style: TextStyle(
                    color: dark ? Colors.white : AppColors.textPrimaryLight,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  detail,
                  style: TextStyle(color: dark ? Colors.white60 : AppColors.textSecondaryLight, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Breadcrumb extends StatelessWidget {
  const _Breadcrumb(this.parts);
  final List<String> parts;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final muted = dark ? Colors.white38 : Colors.black38;
    return Wrap(
      spacing: 4,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final (i, s) in parts.indexed) ...[
          if (i > 0) Icon(Icons.chevron_right_rounded, size: 16, color: muted),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: dark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              s,
              style: TextStyle(
                color: dark ? Colors.white : AppColors.textPrimaryLight,
                fontSize: 12,
                fontWeight: i == parts.length - 1 ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _Step {
  const _Step({required this.icon, required this.title, this.subtitle, this.child, this.last = false});
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? child;
  final bool last;
}

/// Pasos numerados unidos por una línea vertical.
class _Timeline extends StatelessWidget {
  const _Timeline({required this.steps});
  final List<_Step> steps;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fg = dark ? Colors.white : AppColors.textPrimaryLight;
    final muted = dark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final line = dark ? Colors.white12 : Colors.black12;

    return Column(
      children: [
        for (final (i, s) in steps.indexed)
          Stack(
            children: [
              // Línea que une este paso con el siguiente.
              if (!s.last)
                Positioned(left: 19, top: 36, bottom: 0, child: Container(width: 2, color: line)),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 36,
                    alignment: Alignment.center,
                    child: Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                      child: Text(
                        '${i + 1}',
                        style: const TextStyle(color: AppColors.onAccent, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: s.last ? 0 : 22, top: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(s.icon, size: 18, color: dark ? AppColors.accent : AppColors.accentOnLight),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(s.title, style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 15.5)),
                              ),
                            ],
                          ),
                          if (s.subtitle != null) ...[
                            const SizedBox(height: 4),
                            Text(s.subtitle!, style: TextStyle(color: muted, fontSize: 13, height: 1.4)),
                          ],
                          if (s.child != null) ...[const SizedBox(height: 10), s.child!],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
      ],
    );
  }
}
