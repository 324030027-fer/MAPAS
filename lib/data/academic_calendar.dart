import 'package:flutter/material.dart';

/// Grupos de eventos, para los filtros del calendario.
enum CalendarGroup {
  cuatrimestre('Cuatrimestre', Icons.flag_rounded),
  sinClases('Días sin clases', Icons.beach_access_rounded),
  tramites('Trámites escolares', Icons.assignment_rounded),
  admision('Admisión', Icons.how_to_reg_rounded);

  const CalendarGroup(this.label, this.icon);
  final String label;
  final IconData icon;
}

/// Tipos de evento del calendario oficial UPJR, con el color de su leyenda.
enum CalendarEventType {
  inicioCuatrimestre('Inicio de cuatrimestre', Color(0xFF2FA36B), Icons.flag_rounded, CalendarGroup.cuatrimestre),
  terminoCuatrimestre('Término de cuatrimestre', Color(0xFF3B8EEA), Icons.sports_score_rounded, CalendarGroup.cuatrimestre),
  asueto('Asueto', Color(0xFFF2C230), Icons.celebration_rounded, CalendarGroup.sinClases),
  vacaciones('Vacaciones', Color(0xFFE5484D), Icons.beach_access_rounded, CalendarGroup.sinClases),
  vacacionesConPersonal(
    'Vacaciones con personal para inscripción y reinscripción',
    Color(0xFFEF7D57),
    Icons.support_agent_rounded,
    CalendarGroup.sinClases,
  ),
  vacacionesEjercicioAnterior(
    'Periodo vacacional del ejercicio anterior',
    Color(0xFF3D5A8C),
    Icons.history_rounded,
    CalendarGroup.sinClases,
  ),
  inicioReinscripciones('Inicio de reinscripciones', Color(0xFFD9A066), Icons.how_to_reg_rounded, CalendarGroup.tramites),
  cierreInscripcion(
    'Cierre de inscripción y reinscripción',
    Color(0xFF8E96A8),
    Icons.lock_clock_rounded,
    CalendarGroup.tramites,
  ),
  cierreCargas('Cierre de sistema para cargas académicas', Color(0xFFD98C95), Icons.event_busy_rounded, CalendarGroup.tramites),
  descargaMaterias('Descarga de materias en cargas académicas', Color(0xFFA8423F), Icons.download_rounded, CalendarGroup.tramites),
  cierreSolicitudes(
    'Cierre de solicitudes de competencias y especiales; trámites de equivalencia',
    Color(0xFFB07AA1),
    Icons.assignment_late_rounded,
    CalendarGroup.tramites,
  ),
  reporteCalificaciones(
    'Reporte administrativo de calificaciones',
    Color(0xFF8DBF6A),
    Icons.grading_rounded,
    CalendarGroup.tramites,
  ),
  examenAdmision('Examen de admisión', Color(0xFF2F86B8), Icons.edit_note_rounded, CalendarGroup.admision),
  fichas('Expedición de fichas', Color(0xFF7C8CF0), Icons.confirmation_number_rounded, CalendarGroup.admision);

  const CalendarEventType(this.label, this.color, this.icon, this.group);
  final String label;
  final Color color;
  final IconData icon;
  final CalendarGroup group;

  /// Días en que no hay clases (para resaltar el día completo).
  bool get isNoClass => group == CalendarGroup.sinClases;
}

/// Un evento de uno o varios días (fechas inclusivas, sin hora).
class CalendarEvent {
  CalendarEvent(this.type, DateTime start, [DateTime? end, this.title])
      : start = DateUtils.dateOnly(start),
        end = DateUtils.dateOnly(end ?? start);

  final CalendarEventType type;
  final DateTime start;
  final DateTime end;

  /// Texto propio (p. ej. 'Día de la Independencia'); si no, el del tipo.
  final String? title;

  String get label => title ?? type.label;
  bool get isRange => end.isAfter(start);
  bool covers(DateTime day) {
    final d = DateUtils.dateOnly(day);
    return !d.isBefore(start) && !d.isAfter(end);
  }
}

/// Cuatrimestre (de su inicio a su término).
class Term {
  const Term(this.name, this.start, this.end);
  final String name;
  final DateTime start;
  final DateTime end;

  bool contains(DateTime day) {
    final d = DateUtils.dateOnly(day);
    return !d.isBefore(start) && !d.isAfter(end);
  }

  /// Semana del cuatrimestre (1 = la semana del inicio), igual que la
  /// columna SEM del calendario oficial.
  int weekOf(DateTime day) => DateUtils.dateOnly(day).difference(start).inDays ~/ 7 + 1;
  int get totalWeeks => weekOf(end);
}

DateTime _d(int m, int d) => DateTime(2026, m, d);

/// Calendario escolar 2026 de la UPJR (documento firmado por Rectoría).
///
/// Transcrito a mano del PDF oficial: si la universidad publica cambios,
/// actualiza aquí. Revisar contra el original: 4 de mayo (cierre de
/// inscripción) y 17–18 de diciembre (vacaciones con personal).
class AcademicCalendar {
  static const year = 2026;

  static final List<Term> terms = [
    Term('Enero – Abril', _d(1, 5), _d(4, 30)),
    Term('Mayo – Agosto', _d(5, 4), _d(8, 21)),
    Term('Septiembre – Diciembre', _d(8, 31), _d(12, 11)),
  ];

  static final List<CalendarEvent> events = [
    // Enero
    CalendarEvent(CalendarEventType.asueto, _d(1, 1), null, 'Año Nuevo'),
    CalendarEvent(CalendarEventType.vacacionesEjercicioAnterior, _d(1, 2)),
    CalendarEvent(CalendarEventType.inicioCuatrimestre, _d(1, 5), null, 'Inicio del cuatrimestre Enero – Abril'),
    CalendarEvent(CalendarEventType.cierreInscripcion, _d(1, 16)),
    // Febrero
    CalendarEvent(CalendarEventType.asueto, _d(2, 2), null, 'Día de la Constitución'),
    CalendarEvent(CalendarEventType.fichas, _d(2, 3), null, 'Inicio de expedición de fichas'),
    CalendarEvent(CalendarEventType.descargaMaterias, _d(2, 6)),
    CalendarEvent(CalendarEventType.cierreSolicitudes, _d(2, 9)),
    CalendarEvent(CalendarEventType.reporteCalificaciones, _d(2, 16), _d(2, 20)),
    // Marzo
    CalendarEvent(CalendarEventType.asueto, _d(3, 16), null, 'Natalicio de Benito Juárez'),
    CalendarEvent(CalendarEventType.asueto, _d(3, 30), _d(4, 3), 'Asueto de Semana Santa'),
    // Abril
    CalendarEvent(CalendarEventType.vacaciones, _d(4, 6), _d(4, 10), 'Vacaciones de Pascua'),
    CalendarEvent(CalendarEventType.inicioReinscripciones, _d(4, 20)),
    CalendarEvent(CalendarEventType.reporteCalificaciones, _d(4, 27), _d(4, 29)),
    CalendarEvent(CalendarEventType.terminoCuatrimestre, _d(4, 30), null, 'Fin del cuatrimestre Enero – Abril'),
    // Mayo
    CalendarEvent(CalendarEventType.asueto, _d(5, 1), null, 'Día del Trabajo'),
    CalendarEvent(CalendarEventType.inicioCuatrimestre, _d(5, 4), null, 'Inicio del cuatrimestre Mayo – Agosto'),
    CalendarEvent(CalendarEventType.cierreInscripcion, _d(5, 4)),
    CalendarEvent(CalendarEventType.cierreCargas, _d(5, 14)),
    CalendarEvent(CalendarEventType.asueto, _d(5, 15), null, 'Día del Maestro'),
    CalendarEvent(CalendarEventType.examenAdmision, _d(5, 23)),
    // Junio
    CalendarEvent(CalendarEventType.descargaMaterias, _d(6, 5)),
    CalendarEvent(CalendarEventType.cierreSolicitudes, _d(6, 8)),
    CalendarEvent(CalendarEventType.reporteCalificaciones, _d(6, 15), _d(6, 19)),
    CalendarEvent(CalendarEventType.examenAdmision, _d(6, 27)),
    // Julio
    CalendarEvent(CalendarEventType.fichas, _d(7, 17), null, 'Término de expedición de fichas'),
    CalendarEvent(CalendarEventType.vacaciones, _d(7, 27), _d(7, 31), 'Vacaciones de verano'),
    // Agosto
    CalendarEvent(CalendarEventType.examenAdmision, _d(8, 8)),
    CalendarEvent(CalendarEventType.inicioReinscripciones, _d(8, 10)),
    CalendarEvent(CalendarEventType.reporteCalificaciones, _d(8, 11), _d(8, 14)),
    CalendarEvent(CalendarEventType.reporteCalificaciones, _d(8, 17), _d(8, 20)),
    CalendarEvent(CalendarEventType.terminoCuatrimestre, _d(8, 21), null, 'Fin del cuatrimestre Mayo – Agosto'),
    CalendarEvent(CalendarEventType.cierreInscripcion, _d(8, 28)),
    CalendarEvent(CalendarEventType.inicioCuatrimestre, _d(8, 31), null, 'Inicio del cuatrimestre Septiembre – Diciembre'),
    // Septiembre
    CalendarEvent(CalendarEventType.cierreCargas, _d(9, 11)),
    CalendarEvent(CalendarEventType.asueto, _d(9, 16), null, 'Día de la Independencia'),
    CalendarEvent(CalendarEventType.fichas, _d(9, 28), null, 'Inicio de expedición de fichas'),
    // Octubre
    CalendarEvent(CalendarEventType.descargaMaterias, _d(10, 2)),
    CalendarEvent(CalendarEventType.cierreSolicitudes, _d(10, 5)),
    CalendarEvent(CalendarEventType.reporteCalificaciones, _d(10, 12), _d(10, 16)),
    // Noviembre
    CalendarEvent(CalendarEventType.asueto, _d(11, 2), null, 'Día de Muertos'),
    CalendarEvent(CalendarEventType.asueto, _d(11, 16), null, 'Día de la Revolución'),
    CalendarEvent(CalendarEventType.reporteCalificaciones, _d(11, 30), _d(12, 4)),
    // Diciembre
    CalendarEvent(CalendarEventType.reporteCalificaciones, _d(12, 7), _d(12, 10)),
    CalendarEvent(CalendarEventType.terminoCuatrimestre, _d(12, 11), null, 'Fin del cuatrimestre Septiembre – Diciembre'),
    CalendarEvent(CalendarEventType.fichas, _d(12, 11), null, 'Término de expedición de fichas'),
    CalendarEvent(CalendarEventType.asueto, _d(12, 12), null, 'Día de la Virgen de Guadalupe'),
    CalendarEvent(CalendarEventType.vacacionesConPersonal, _d(12, 17), _d(12, 18)),
    CalendarEvent(CalendarEventType.vacaciones, _d(12, 21), _d(12, 24), 'Vacaciones de invierno'),
    CalendarEvent(CalendarEventType.asueto, _d(12, 25), null, 'Navidad'),
    CalendarEvent(CalendarEventType.vacaciones, _d(12, 28), _d(12, 31), 'Vacaciones de invierno'),
  ];

  /// Eventos de un día.
  static List<CalendarEvent> on(DateTime day) => [for (final e in events) if (e.covers(day)) e];

  /// Eventos que tocan un mes.
  static List<CalendarEvent> inMonth(int month) {
    final first = DateTime(year, month);
    final last = DateTime(year, month + 1, 0);
    return [for (final e in events) if (!e.end.isBefore(first) && !e.start.isAfter(last)) e];
  }

  /// Próximos eventos desde [from] (incluye los que están en curso).
  static List<CalendarEvent> upcoming(DateTime from, {int count = 3}) {
    final d = DateUtils.dateOnly(from);
    final list = [for (final e in events) if (!e.end.isBefore(d)) e]..sort((a, b) => a.start.compareTo(b.start));
    return list.take(count).toList();
  }

  static Term? termOf(DateTime day) {
    for (final t in terms) {
      if (t.contains(day)) return t;
    }
    return null;
  }

  static Term? nextTerm(DateTime day) {
    final d = DateUtils.dateOnly(day);
    for (final t in terms) {
      if (t.start.isAfter(d)) return t;
    }
    return null;
  }
}

/// Nombres en español (sin depender de intl).
const kMonthNames = [
  'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
  'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
];
const kWeekdayShort = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
const kWeekdayNames = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];

String formatDay(DateTime d) => '${kWeekdayNames[d.weekday - 1]} ${d.day} de ${kMonthNames[d.month - 1].toLowerCase()}';
String formatShort(DateTime d) => '${d.day} ${kMonthNames[d.month - 1].substring(0, 3).toLowerCase()}';
String formatRange(CalendarEvent e) => e.isRange
    ? (e.start.month == e.end.month
        ? '${e.start.day}–${e.end.day} ${kMonthNames[e.start.month - 1].substring(0, 3).toLowerCase()}'
        : '${formatShort(e.start)} – ${formatShort(e.end)}')
    : formatShort(e.start);
