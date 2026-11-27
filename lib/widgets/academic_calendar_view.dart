import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../data/academic_calendar.dart';
import 'glass.dart';

/// Colores según el tema.
class _Ink {
  _Ink(BuildContext context) : dark = Theme.of(context).brightness == Brightness.dark;
  final bool dark;
  Color get fg => dark ? Colors.white : AppColors.textPrimaryLight;
  Color get muted => dark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
  Color get faint => dark ? Colors.white24 : Colors.black26;
  Color get surface => dark ? Colors.white.withValues(alpha: 0.06) : Colors.white.withValues(alpha: 0.7);
  Color get border => dark ? Colors.white.withValues(alpha: 0.10) : Colors.black.withValues(alpha: 0.07);
  Color get accentText => dark ? AppColors.accent : AppColors.accentOnLight;
}

/// Calendario escolar interactivo: cuatrimestre en curso, próximos eventos,
/// vista de mes con días de color, filtros por tipo y detalle del día.
class AcademicCalendarView extends StatefulWidget {
  const AcademicCalendarView({super.key, this.today});

  /// Fecha de "hoy" (para pruebas); por defecto la del dispositivo.
  final DateTime? today;

  @override
  State<AcademicCalendarView> createState() => _AcademicCalendarViewState();
}

class _AcademicCalendarViewState extends State<AcademicCalendarView> {
  late final DateTime _today = DateUtils.dateOnly(widget.today ?? DateTime.now());
  late int _month;
  late DateTime _selected;
  int _direction = 1; // para la animación al cambiar de mes
  final Set<CalendarGroup> _groups = {...CalendarGroup.values};

  @override
  void initState() {
    super.initState();
    final inYear = _today.year == AcademicCalendar.year;
    _month = inYear ? _today.month : (_today.year < AcademicCalendar.year ? 1 : 12);
    _selected = inYear ? _today : DateTime(AcademicCalendar.year, _month, 1);
  }

  void _goToMonth(int m) {
    if (m < 1 || m > 12 || m == _month) return;
    setState(() {
      _direction = m > _month ? 1 : -1;
      _month = m;
      // Al cambiar de mes se selecciona el primer día con eventos (o el 1).
      final first = AcademicCalendar.inMonth(m).where(_visible).firstOrNull;
      _selected = first == null
          ? DateTime(AcademicCalendar.year, m, 1)
          : (first.start.month == m ? first.start : DateTime(AcademicCalendar.year, m, 1));
      if (_today.year == AcademicCalendar.year && _today.month == m) _selected = _today;
    });
  }

  void _goToday() {
    if (_today.year != AcademicCalendar.year) return;
    setState(() {
      _direction = _today.month >= _month ? 1 : -1;
      _month = _today.month;
      _selected = _today;
    });
  }

  bool _visible(CalendarEvent e) => _groups.contains(e.type.group);

  void _jumpTo(CalendarEvent e) {
    setState(() {
      _direction = e.start.month >= _month ? 1 : -1;
      _month = e.start.month;
      _selected = e.start;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ink = _Ink(context);

    final monthCard = GlassContainer(
      radius: 24,
      blur: 10,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _MonthHeader(
            month: _month,
            onPrev: _month > 1 ? () => _goToMonth(_month - 1) : null,
            onNext: _month < 12 ? () => _goToMonth(_month + 1) : null,
            onToday: _today.year == AcademicCalendar.year && (_month != _today.month || _selected != _today)
                ? _goToday
                : null,
          ),
          const SizedBox(height: 10),
          _MonthPills(month: _month, today: _today, onTap: _goToMonth),
          const SizedBox(height: 14),
          GestureDetector(
            // Deslizar a los lados cambia de mes.
            onHorizontalDragEnd: (d) {
              final v = d.primaryVelocity ?? 0;
              if (v < -200) _goToMonth(_month + 1);
              if (v > 200) _goToMonth(_month - 1);
            },
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, anim) {
                final incoming = child.key == ValueKey(_month);
                final dx = (incoming ? 0.12 : -0.12) * _direction;
                return FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween(begin: Offset(dx, 0), end: Offset.zero).animate(anim),
                    child: child,
                  ),
                );
              },
              layoutBuilder: (current, previous) => Stack(
                alignment: Alignment.topCenter,
                children: [...previous, ?current],
              ),
              child: _MonthGrid(
                key: ValueKey(_month),
                month: _month,
                today: _today,
                selected: _selected,
                visible: _visible,
                onSelect: (d) => setState(() => _selected = d),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _GroupFilters(
            active: _groups,
            onToggle: (g) => setState(() {
              if (_groups.contains(g)) {
                if (_groups.length > 1) _groups.remove(g);
              } else {
                _groups.add(g);
              }
            }),
          ),
        ],
      ),
    );

    final dayDetail =
        _DayDetail(day: _selected, today: _today, events: AcademicCalendar.on(_selected).where(_visible).toList());
    final agendaTitle = Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        'EVENTOS DE ${kMonthNames[_month - 1].toUpperCase()}',
        style: TextStyle(color: ink.muted, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.3),
      ),
    );
    final agenda = _MonthAgenda(
      month: _month,
      today: _today,
      selected: _selected,
      events: AcademicCalendar.inMonth(_month).where(_visible).toList(),
      onTap: (e) => setState(() => _selected = e.start.month == _month ? e.start : _selected),
    );

    return LayoutBuilder(builder: (context, box) {
      // PC / tableta horizontal: el mes a la izquierda y el detalle a la
      // derecha, todo a la vista sin desplazarse tanto.
      if (box.maxWidth >= 860) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 11,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [_TermCard(today: _today), const SizedBox(height: 16), monthCard],
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              flex: 9,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  dayDetail,
                  const SizedBox(height: 16),
                  _UpcomingStrip(today: _today, onTap: _jumpTo, vertical: true),
                  const SizedBox(height: 16),
                  agendaTitle,
                  agenda,
                ],
              ),
            ),
          ],
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TermCard(today: _today),
          const SizedBox(height: 14),
          _UpcomingStrip(today: _today, onTap: _jumpTo),
          const SizedBox(height: 14),
          monthCard,
          const SizedBox(height: 14),
          dayDetail,
          const SizedBox(height: 14),
          agendaTitle,
          agenda,
        ],
      );
    });
  }
}

// ---------------------------------------------------------------------------
// Cuatrimestre en curso

class _TermCard extends StatelessWidget {
  const _TermCard({required this.today});
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final ink = _Ink(context);
    final term = AcademicCalendar.termOf(today);
    final next = AcademicCalendar.nextTerm(today);

    String title, subtitle;
    double? progress;
    String? weekLabel;
    if (term != null) {
      final week = term.weekOf(today);
      final left = term.end.difference(today).inDays;
      title = 'Cuatrimestre ${term.name}';
      weekLabel = 'Semana $week de ${term.totalWeeks}';
      subtitle = left == 0 ? 'Hoy termina el cuatrimestre' : 'Termina el ${formatShort(term.end)} · faltan $left días';
      progress = (today.difference(term.start).inDays + 1) / (term.end.difference(term.start).inDays + 1);
    } else if (next != null) {
      final left = next.start.difference(today).inDays;
      title = 'Entre cuatrimestres';
      subtitle = 'El cuatrimestre ${next.name} inicia el ${formatShort(next.start)} (en $left días)';
    } else {
      title = 'Calendario ${AcademicCalendar.year}';
      subtitle = today.year > AcademicCalendar.year
          ? 'Este calendario ya terminó; pronto se publicará el siguiente.'
          : 'El primer cuatrimestre inicia el ${formatShort(AcademicCalendar.terms.first.start)}.';
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: ink.dark
              ? [const Color(0xFF34404F), const Color(0xFF263042)]
              : [Colors.white, const Color(0xFFFFF4E2)],
        ),
        border: Border.all(color: AppColors.accent.withValues(alpha: ink.dark ? 0.35 : 0.5)),
      ),
      child: Row(
        children: [
          // Anillo de avance: la semana actual de un vistazo.
          SizedBox(
            width: 68,
            height: 68,
            child: progress == null
                ? Container(
                    decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.2), shape: BoxShape.circle),
                    child: Icon(Icons.school_rounded, color: ink.accentText, size: 30),
                  )
                : TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: progress.clamp(0, 1)),
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeOutCubic,
                    builder: (_, v, __) => Stack(
                      fit: StackFit.expand,
                      children: [
                        CircularProgressIndicator(
                          value: v,
                          strokeWidth: 7,
                          strokeCap: StrokeCap.round,
                          backgroundColor: ink.dark ? Colors.white12 : Colors.black12,
                          valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                        ),
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${term!.weekOf(today)}',
                                style: TextStyle(color: ink.fg, fontSize: 20, fontWeight: FontWeight.w900, height: 1),
                              ),
                              Text('de ${term.totalWeeks}', style: TextStyle(color: ink.muted, fontSize: 10.5)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  weekLabel == null ? formatDay(today) : '${formatDay(today)} · $weekLabel',
                  style: TextStyle(color: ink.accentText, fontSize: 12, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(title, style: TextStyle(color: ink.fg, fontSize: 17, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: ink.muted, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Próximos eventos

class _UpcomingStrip extends StatelessWidget {
  const _UpcomingStrip({required this.today, required this.onTap, this.vertical = false});
  final DateTime today;
  final ValueChanged<CalendarEvent> onTap;

  /// En columna (PC): filas compactas en lugar de tarjetas deslizables.
  final bool vertical;

  static String countdown(CalendarEvent e, DateTime today) {
    if (e.covers(today)) return e.isRange ? 'En curso' : 'Hoy';
    final days = e.start.difference(today).inDays;
    if (days == 1) return 'Mañana';
    if (days < 7) return 'En $days días';
    if (days < 14) return 'En 1 semana';
    if (days < 60) return 'En ${days ~/ 7} semanas';
    return 'En ${days ~/ 30} meses';
  }

  @override
  Widget build(BuildContext context) {
    final ink = _Ink(context);
    final list = AcademicCalendar.upcoming(today, count: 4);
    if (list.isEmpty) return const SizedBox.shrink();
    if (vertical) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'PRÓXIMOS',
              style: TextStyle(color: ink.muted, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.3),
            ),
          ),
          GlassContainer(
            radius: 20,
            blur: 0,
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                for (final e in list)
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => onTap(e),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                        child: Row(
                          children: [
                            Container(
                              width: 4,
                              height: 34,
                              decoration: BoxDecoration(color: e.type.color, borderRadius: BorderRadius.circular(2)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    e.label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: ink.fg, fontSize: 13.5, fontWeight: FontWeight.w700),
                                  ),
                                  Text(formatRange(e), style: TextStyle(color: ink.muted, fontSize: 12)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              countdown(e, today),
                              style: TextStyle(color: ink.accentText, fontSize: 12, fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'PRÓXIMOS',
            style: TextStyle(color: ink.muted, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.3),
          ),
        ),
        SizedBox(
          height: 112,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final e = list[i];
              final c = e.type.color;
              return Material(
                color: ink.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(color: ink.border),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => onTap(e),
                  child: Container(
                    width: 190,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border(left: BorderSide(color: c, width: 4)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(e.type.icon, size: 16, color: c),
                            const SizedBox(width: 6),
                            Text(
                              countdown(e, today),
                              style: TextStyle(color: ink.accentText, fontSize: 12, fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Expanded(
                          child: Text(
                            e.label,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: ink.fg, fontSize: 13.5, fontWeight: FontWeight.w700, height: 1.2),
                          ),
                        ),
                        Text(formatRange(e), style: TextStyle(color: ink.muted, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Encabezado del mes y selector rápido

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({required this.month, this.onPrev, this.onNext, this.onToday});
  final int month;
  final VoidCallback? onPrev, onNext, onToday;

  @override
  Widget build(BuildContext context) {
    final ink = _Ink(context);
    return Row(
      children: [
        IconButton(
          tooltip: 'Mes anterior',
          onPressed: onPrev,
          icon: const Icon(Icons.chevron_left_rounded),
          color: ink.fg,
          disabledColor: ink.faint,
        ),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              '${kMonthNames[month - 1]} ${AcademicCalendar.year}',
              key: ValueKey(month),
              textAlign: TextAlign.center,
              style: TextStyle(color: ink.fg, fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ),
        ),
        if (onToday != null)
          TextButton(
            onPressed: onToday,
            style: TextButton.styleFrom(foregroundColor: ink.accentText, visualDensity: VisualDensity.compact),
            child: const Text('Hoy'),
          ),
        IconButton(
          tooltip: 'Mes siguiente',
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right_rounded),
          color: ink.fg,
          disabledColor: ink.faint,
        ),
      ],
    );
  }
}

class _MonthPills extends StatefulWidget {
  const _MonthPills({required this.month, required this.today, required this.onTap});
  final int month;
  final DateTime today;
  final ValueChanged<int> onTap;

  @override
  State<_MonthPills> createState() => _MonthPillsState();
}

class _MonthPillsState extends State<_MonthPills> {
  final _scroll = ScrollController();
  static const _w = 52.0, _gap = 6.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _center(animate: false));
  }

  @override
  void didUpdateWidget(_MonthPills old) {
    super.didUpdateWidget(old);
    if (old.month != widget.month) _center();
  }

  void _center({bool animate = true}) {
    if (!_scroll.hasClients) return;
    final pos = _scroll.position;
    final target = ((widget.month - 1) * (_w + _gap) - (pos.viewportDimension - _w) / 2)
        .clamp(pos.minScrollExtent, pos.maxScrollExtent);
    animate
        ? _scroll.animateTo(target, duration: const Duration(milliseconds: 250), curve: Curves.easeOut)
        : _scroll.jumpTo(target);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ink = _Ink(context);
    return LayoutBuilder(builder: (context, box) {
      // Si caben los 12 meses, se reparten a lo ancho sin desplazamiento.
      if (box.maxWidth >= 12 * 38) {
        return SizedBox(
          height: 34,
          child: Row(
            children: [
              for (var i = 0; i < 12; i++) ...[
                if (i > 0) const SizedBox(width: 4),
                Expanded(child: _pill(ink, i)),
              ],
            ],
          ),
        );
      }
      return _scrollPills(ink);
    });
  }

  Widget _pill(_Ink ink, int i) {
    final m = i + 1;
    final selected = m == widget.month;
    final isNow = widget.today.year == AcademicCalendar.year && widget.today.month == m;
    return Material(
      color: selected ? AppColors.accent : ink.surface,
      shape: StadiumBorder(
        side: BorderSide(color: selected ? AppColors.accent : (isNow ? ink.accentText : ink.border)),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: () => widget.onTap(m),
        child: Center(
          child: Text(
            kMonthNames[i].substring(0, 3),
            style: TextStyle(
              color: selected ? AppColors.onAccent : ink.fg,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              fontSize: 12.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _scrollPills(_Ink ink) {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        controller: _scroll,
        scrollDirection: Axis.horizontal,
        itemCount: 12,
        separatorBuilder: (_, __) => const SizedBox(width: _gap),
        itemBuilder: (context, i) {
          final m = i + 1;
          final selected = m == widget.month;
          final isNow = widget.today.year == AcademicCalendar.year && widget.today.month == m;
          return SizedBox(
            width: _w,
            child: Material(
              color: selected ? AppColors.accent : ink.surface,
              shape: StadiumBorder(
                side: BorderSide(color: selected ? AppColors.accent : (isNow ? ink.accentText : ink.border)),
              ),
              child: InkWell(
                customBorder: const StadiumBorder(),
                onTap: () => widget.onTap(m),
                child: Center(
                  child: Text(
                    kMonthNames[i].substring(0, 3),
                    style: TextStyle(
                      color: selected ? AppColors.onAccent : ink.fg,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      fontSize: 12.5,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Cuadrícula del mes

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    super.key,
    required this.month,
    required this.today,
    required this.selected,
    required this.visible,
    required this.onSelect,
  });
  final int month;
  final DateTime today;
  final DateTime selected;
  final bool Function(CalendarEvent) visible;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final ink = _Ink(context);
    final first = DateTime(AcademicCalendar.year, month, 1);
    final days = DateUtils.getDaysInMonth(AcademicCalendar.year, month);
    final lead = first.weekday - 1; // lunes = 0
    final cells = lead + days;
    final rows = (cells / 7).ceil();

    return LayoutBuilder(builder: (context, box) {
      // Celdas más altas cuando hay espacio (PC), sin volverse franjas planas.
      final cellH = (box.maxWidth / 7 * 0.72).clamp(42.0, 58.0);
      return Column(
      children: [
        Row(
          children: [
            for (var i = 0; i < 7; i++)
              Expanded(
                child: Center(
                  child: Text(
                    kWeekdayShort[i],
                    style: TextStyle(
                      color: i >= 5 ? ink.faint : ink.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        for (var r = 0; r < rows; r++)
          Row(
            children: [
              for (var c = 0; c < 7; c++)
                Expanded(
                  child: Builder(builder: (context) {
                    final n = r * 7 + c - lead + 1;
                    if (n < 1 || n > days) return SizedBox(height: cellH + 4);
                    final day = DateTime(AcademicCalendar.year, month, n);
                    return _DayCell(
                      day: day,
                      events: AcademicCalendar.on(day).where(visible).toList(),
                      isToday: day == today,
                      isSelected: day == selected,
                      weekend: c >= 5,
                      height: cellH,
                      onTap: () => onSelect(day),
                    );
                  }),
                ),
            ],
          ),
      ],
    );
    });
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.events,
    required this.isToday,
    required this.isSelected,
    required this.weekend,
    required this.onTap,
    this.height = 42,
  });
  final double height;
  final DateTime day;
  final List<CalendarEvent> events;
  final bool isToday, isSelected, weekend;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ink = _Ink(context);
    final main = events.isEmpty ? null : events.first;
    // Días sin clases: relleno fuerte; trámites y demás: relleno suave.
    final fill = main == null
        ? Colors.transparent
        : main.type.color.withValues(alpha: main.type.isNoClass ? (ink.dark ? 0.55 : 0.45) : (ink.dark ? 0.26 : 0.22));
    final textColor = isSelected
        ? AppColors.onAccent
        : (weekend && main == null ? ink.faint : ink.fg);

    return Padding(
      padding: const EdgeInsets.all(2),
      child: Semantics(
        button: true,
        selected: isSelected,
        label: '${formatDay(day)}${events.isEmpty ? '' : ': ${events.map((e) => e.label).join(', ')}'}',
        child: Material(
          color: isSelected ? AppColors.accent : fill,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isToday && !isSelected
                ? BorderSide(color: ink.accentText, width: 2)
                : BorderSide.none,
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: SizedBox(
              height: height,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${day.day}',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 14,
                      fontWeight: isToday || isSelected || main != null ? FontWeight.w800 : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 3),
                  // Un punto por evento (máx. 3), del color de su tipo.
                  SizedBox(
                    height: 5,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (final e in events.take(3))
                          Container(
                            width: 5,
                            height: 5,
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected ? AppColors.onAccent : e.type.color,
                              border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 0.5),
                            ),
                          ),
                      ],
                    ),
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

// ---------------------------------------------------------------------------
// Filtros por grupo (también sirven de leyenda)

class _GroupFilters extends StatelessWidget {
  const _GroupFilters({required this.active, required this.onToggle});
  final Set<CalendarGroup> active;
  final ValueChanged<CalendarGroup> onToggle;

  @override
  Widget build(BuildContext context) {
    final ink = _Ink(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final g in CalendarGroup.values)
          FilterChip(
            selected: active.contains(g),
            showCheckmark: false,
            onSelected: (_) => onToggle(g),
            // Puntos de colores del grupo, encimados para caber en el avatar.
            avatar: SizedBox(
              width: 18,
              height: 10,
              child: Stack(
                children: [
                  for (final (i, t) in CalendarEventType.values.where((t) => t.group == g).take(3).indexed)
                    Positioned(
                      left: i * 4.0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: t.color,
                          border: Border.all(color: Colors.black.withValues(alpha: 0.25), width: 0.5),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            label: Text(g.label),
            labelStyle: TextStyle(
              color: active.contains(g) ? ink.fg : ink.muted,
              fontSize: 12,
              fontWeight: active.contains(g) ? FontWeight.w700 : FontWeight.w500,
              decoration: active.contains(g) ? null : TextDecoration.lineThrough,
            ),
            backgroundColor: ink.surface,
            selectedColor: AppColors.accent.withValues(alpha: ink.dark ? 0.22 : 0.18),
            side: BorderSide(color: active.contains(g) ? AppColors.accent.withValues(alpha: 0.6) : ink.border),
            shape: const StadiumBorder(),
            visualDensity: VisualDensity.compact,
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Detalle del día seleccionado y agenda del mes

class _DayDetail extends StatelessWidget {
  const _DayDetail({required this.day, required this.today, required this.events});
  final DateTime day;
  final DateTime today;
  final List<CalendarEvent> events;

  @override
  Widget build(BuildContext context) {
    final ink = _Ink(context);
    final term = AcademicCalendar.termOf(day);
    final weekend = day.weekday >= 6;
    final noClass = events.any((e) => e.type.isNoClass);
    final status = noClass || weekend
        ? 'Sin clases'
        : term != null
            ? 'Día de clases · semana ${term.weekOf(day)}'
            : 'Fuera de cuatrimestre';

    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      alignment: Alignment.topCenter,
      child: GlassContainer(
        radius: 20,
        blur: 0,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    day == today ? 'Hoy · ${formatDay(day)}' : formatDay(day),
                    style: TextStyle(color: ink.fg, fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: (noClass || weekend ? AppColors.danger : const Color(0xFF2FA36B)).withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: noClass || weekend
                          ? (ink.dark ? const Color(0xFFFF8A8D) : const Color(0xFFB3261E))
                          : (ink.dark ? const Color(0xFF7EE0A8) : const Color(0xFF1E7A4C)),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (events.isEmpty)
              Text('Sin eventos del calendario escolar.', style: TextStyle(color: ink.muted, fontSize: 13))
            else
              for (final e in events) _EventRow(event: e),
          ],
        ),
      ),
    );
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({required this.event, this.highlight = false, this.onTap, this.dimmed = false});
  final CalendarEvent event;
  final bool highlight;
  final bool dimmed;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ink = _Ink(context);
    final c = event.type.color;
    return Opacity(
      opacity: dimmed ? 0.55 : 1,
      child: Material(
        color: highlight ? AppColors.accent.withValues(alpha: ink.dark ? 0.14 : 0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(color: c.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                  child: Icon(event.type.icon, color: c, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(event.label, style: TextStyle(color: ink.fg, fontSize: 13.5, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(
                        event.title == null ? formatRange(event) : '${event.type.label} · ${formatRange(event)}',
                        style: TextStyle(color: ink.muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MonthAgenda extends StatelessWidget {
  const _MonthAgenda({
    required this.month,
    required this.today,
    required this.selected,
    required this.events,
    required this.onTap,
  });
  final int month;
  final DateTime today;
  final DateTime selected;
  final List<CalendarEvent> events;
  final ValueChanged<CalendarEvent> onTap;

  @override
  Widget build(BuildContext context) {
    final ink = _Ink(context);
    if (events.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(8),
        child: Text('No hay eventos este mes con los filtros elegidos.', style: TextStyle(color: ink.muted)),
      );
    }
    return GlassContainer(
      radius: 20,
      blur: 0,
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          for (final e in events)
            _EventRow(
              event: e,
              highlight: e.covers(selected),
              dimmed: e.end.isBefore(today),
              onTap: () => onTap(e),
            ),
        ],
      ),
    );
  }
}
