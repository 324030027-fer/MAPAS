import '../../core/schedule_constants.dart';
import '../../models/lab_schedule.dart';

String currentDayName() {
  final weekday = DateTime.now().weekday;
  if (weekday >= 1 && weekday <= kWeekDays.length) {
    return kWeekDays[weekday - 1];
  }
  // Fin de semana: no hay clases.
  return '';
}

int _minutesFromTime(String time) {
  final parts = time.split(':');
  if (parts.length < 2) return 0;
  return (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
}

bool isScheduleEntryNow(ScheduleEntry entry) {
  if (entry.day != currentDayName()) return false;
  final now = DateTime.now();
  final current = now.hour * 60 + now.minute;
  final start = _minutesFromTime(entry.startTime);
  final end = _minutesFromTime(entry.endTime);
  return current >= start && current < end;
}

bool isValidTimeRange(String start, String end) {
  return _minutesFromTime(end) > _minutesFromTime(start);
}

List<ScheduleEntry> entriesHappeningNow(List<LabSchedule> labs) {
  final results = <ScheduleEntry>[];
  for (final lab in labs) {
    for (final entry in lab.entries) {
      if (isScheduleEntryNow(entry)) results.add(entry);
    }
  }
  return results;
}
