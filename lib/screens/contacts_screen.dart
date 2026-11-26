import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/theme/app_colors.dart';
import '../data/rooms.dart' show normalize;
import '../models/contact.dart';
import '../providers/private_data_provider.dart';
import '../widgets/glass.dart';

/// Directorio de profesores: buscador, filtro por clase (carreras, Desarrollo
/// Humano, Inglés) y lista agrupada. Solo nombre, correo y foto.
class ContactsSection extends StatefulWidget {
  const ContactsSection({super.key});

  @override
  State<ContactsSection> createState() => _ContactsSectionState();
}

class _ContactsSectionState extends State<ContactsSection> {
  final _search = TextEditingController();
  String _query = '';
  TeacherGroup? _group; // null = todas

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fg = dark ? Colors.white : AppColors.textPrimaryLight;
    final muted = dark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final data = context.watch<PrivateDataProvider>();
    final all = data.teachers;

    if (all.isEmpty) {
      return GlassContainer(
        radius: 20,
        blur: 0,
        padding: const EdgeInsets.all(24),
        child: Center(
          child: data.loaded
              ? Text('Aún no hay profesores registrados.', style: TextStyle(color: muted))
              : const CircularProgressIndicator(),
        ),
      );
    }

    final q = normalize(_query);
    final filtered = all.where((t) {
      if (_group != null && t.group != _group) return false;
      if (q.isEmpty) return true;
      return normalize('${t.name} ${t.email}').contains(q);
    }).toList();

    // Clases que realmente tienen profesores, en el orden del enum.
    final present = TeacherGroup.values.where((g) => all.any((t) => t.group == g)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlassContainer(
          radius: 16,
          blur: 0,
          child: TextField(
            controller: _search,
            onChanged: (v) => setState(() => _query = v.trim()),
            style: TextStyle(color: fg),
            decoration: InputDecoration(
              hintText: 'Buscar profesor por nombre o correo',
              hintStyle: TextStyle(color: muted, fontSize: 14),
              prefixIcon: Icon(Icons.search_rounded, color: dark ? AppColors.accent : AppColors.accentOnLight),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Borrar',
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () {
                        _search.clear();
                        setState(() => _query = '');
                      },
                    ),
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _GroupChip(label: 'Todos', selected: _group == null, onTap: () => setState(() => _group = null)),
              for (final g in present)
                _GroupChip(
                  label: g.short,
                  icon: g.icon,
                  selected: _group == g,
                  onTap: () => setState(() => _group = _group == g ? null : g),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Ningún profesor coincide con la búsqueda.', style: TextStyle(color: muted)),
          )
        else
          for (final g in TeacherGroup.values)
            if (filtered.any((t) => t.group == g)) ...[
              _GroupHeader(group: g, count: filtered.where((t) => t.group == g).length),
              GlassContainer(
                radius: 20,
                blur: 0,
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  children: [
                    for (final (i, t) in filtered.where((t) => t.group == g).indexed) ...[
                      if (i > 0) Divider(height: 1, indent: 72, color: dark ? Colors.white10 : Colors.black12),
                      _TeacherRow(teacher: t),
                    ],
                  ],
                ),
              ),
            ],
      ],
    );
  }
}

class _GroupChip extends StatelessWidget {
  const _GroupChip({required this.label, required this.selected, required this.onTap, this.icon});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        selected: selected,
        onSelected: (_) => onTap(),
        showCheckmark: false,
        avatar: icon == null
            ? null
            : Icon(icon, size: 16, color: selected ? AppColors.onAccent : (dark ? Colors.white70 : AppColors.textSecondaryLight)),
        label: Text(label),
        labelStyle: TextStyle(
          color: selected ? AppColors.onAccent : (dark ? Colors.white : AppColors.textPrimaryLight),
          fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          fontSize: 12.5,
        ),
        selectedColor: AppColors.accent,
        backgroundColor: dark ? Colors.white.withValues(alpha: 0.06) : Colors.white.withValues(alpha: 0.8),
        side: BorderSide(color: selected ? AppColors.accent : (dark ? Colors.white12 : Colors.black12)),
        shape: const StadiumBorder(),
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.group, required this.count});
  final TeacherGroup group;
  final int count;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final muted = dark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Row(
        children: [
          Icon(group.icon, size: 16, color: dark ? AppColors.accent : AppColors.accentOnLight),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              group.isCareer ? 'Especialidad · ${group.label}' : group.label,
              style: TextStyle(
                color: dark ? Colors.white : AppColors.textPrimaryLight,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text('$count', style: TextStyle(color: muted, fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _TeacherRow extends StatelessWidget {
  const _TeacherRow({required this.teacher});
  final Contact teacher;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fg = dark ? Colors.white : AppColors.textPrimaryLight;
    final muted = dark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    return ListTile(
      onTap: () => showTeacherSheet(context, teacher),
      leading: TeacherAvatar(teacher: teacher, radius: 22),
      title: Text(teacher.name, style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 14.5)),
      subtitle: Text(
        teacher.hasEmail ? teacher.email : 'Correo pendiente',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: muted,
          fontSize: 12.5,
          fontStyle: teacher.hasEmail ? null : FontStyle.italic,
        ),
      ),
      trailing: IconButton(
        tooltip: teacher.hasEmail ? 'Enviar correo' : 'Correo pendiente',
        onPressed: teacher.hasEmail ? () => sendTeacherEmail(context, teacher) : null,
        icon: const Icon(Icons.mail_outline_rounded),
        color: dark ? AppColors.accent : AppColors.accentOnLight,
      ),
    );
  }
}

Future<void> sendTeacherEmail(BuildContext context, Contact teacher) async {
  final uri = Uri(scheme: 'mailto', path: teacher.email);
  var ok = false;
  try {
    ok = await launchUrl(uri);
  } catch (_) {}
  if (!ok && context.mounted) {
    await Clipboard.setData(ClipboardData(text: teacher.email));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay app de correo; copiamos la dirección.'), behavior: SnackBarBehavior.floating),
      );
    }
  }
}

/// Ficha del profesor: foto grande, nombre, clase y correo.
Future<void> showTeacherSheet(BuildContext context, Contact t) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppColors.darkCard : Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (ctx) {
      final dark = Theme.of(ctx).brightness == Brightness.dark;
      final fg = dark ? Colors.white : AppColors.textPrimaryLight;
      final muted = dark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TeacherAvatar(teacher: t, radius: 54),
              const SizedBox(height: 14),
              Text(t.name, textAlign: TextAlign.center, style: TextStyle(color: fg, fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(t.group.icon, size: 16, color: dark ? AppColors.accent : AppColors.accentOnLight),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        t.group.label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: dark ? AppColors.accent : AppColors.accentOnLight,
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
                decoration: BoxDecoration(
                  color: dark ? Colors.white.withValues(alpha: 0.06) : AppColors.lightBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(Icons.alternate_email_rounded, color: muted, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SelectableText(
                        t.hasEmail ? t.email : 'Correo pendiente',
                        style: TextStyle(color: t.hasEmail ? fg : muted, fontSize: 14.5),
                      ),
                    ),
                    if (t.hasEmail)
                      IconButton(
                        tooltip: 'Copiar correo',
                        icon: const Icon(Icons.copy_rounded, size: 20),
                        color: muted,
                        onPressed: () async {
                          await Clipboard.setData(ClipboardData(text: t.email));
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(content: Text('Correo copiado'), behavior: SnackBarBehavior.floating),
                            );
                          }
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: t.hasEmail ? () => sendTeacherEmail(ctx, t) : null,
                  icon: const Icon(Icons.mail_rounded),
                  label: Text(t.hasEmail ? 'Enviar correo' : 'Correo pendiente'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.onAccent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Foto del profesor o, si no hay, sus iniciales.
class TeacherAvatar extends StatelessWidget {
  const TeacherAvatar({super.key, required this.teacher, this.radius = 20});
  final Contact teacher;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final initials = teacher.name
        .split(' ')
        .where((w) => w.isNotEmpty && !w.endsWith('.'))
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();
    final px = (radius * 6).round();
    final ImageProvider? photo = teacher.photoUrl.isNotEmpty
        ? ResizeImage(NetworkImage(teacher.photoUrl), width: px)
        : teacher.imageAsset.isNotEmpty
            ? ResizeImage(AssetImage(teacher.imageAsset), width: px)
            : null;
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.accent.withValues(alpha: 0.18),
      foregroundImage: photo,
      onForegroundImageError: photo == null ? null : (_, __) {},
      child: Text(
        initials,
        style: TextStyle(color: AppColors.accent, fontSize: radius * 0.7, fontWeight: FontWeight.w800),
      ),
    );
  }
}
