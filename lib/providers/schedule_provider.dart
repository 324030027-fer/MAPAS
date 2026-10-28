import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/default_schedules.dart';
import '../models/lab_schedule.dart';

class ScheduleProvider extends ChangeNotifier {
  static const String _storageKey = 'location_schedules_v1';

  Map<String, List<LabSchedule>> _schedulesByLocation = {};
  bool _loaded = false;

  Map<String, List<LabSchedule>> get schedulesByLocation => _schedulesByLocation;

  ScheduleProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);

    if (raw != null && raw.isNotEmpty) {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      _schedulesByLocation = decoded.map((locationId, value) {
        final labs = (value as List)
            .map((e) => LabSchedule.fromJson(e as Map<String, dynamic>))
            .toList();
        return MapEntry(locationId, labs);
      });
    } else {
      _schedulesByLocation = _cloneDefaults();
      await _save();
    }

    _loaded = true;
    notifyListeners();
  }

  Map<String, List<LabSchedule>> _cloneDefaults() {
    return DefaultSchedules.all.map((id, labs) {
      return MapEntry(
        id,
        labs
            .map(
              (lab) => LabSchedule(
                labName: lab.labName,
                entries: lab.entries
                    .map(
                      (e) => ScheduleEntry(
                        id: e.id,
                        day: e.day,
                        startTime: e.startTime,
                        endTime: e.endTime,
                        subject: e.subject,
                        group: e.group,
                        teacher: e.teacher,
                      ),
                    )
                    .toList(),
              ),
            )
            .toList(),
      );
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = _schedulesByLocation.map(
      (key, value) => MapEntry(key, value.map((l) => l.toJson()).toList()),
    );
    await prefs.setString(_storageKey, jsonEncode(encoded));
  }

  List<String> get locationIdsWithSchedules => _schedulesByLocation.keys.toList();

  bool hasSchedulesForLocation(String locationId) {
    final labs = _schedulesByLocation[locationId];
    return labs != null && labs.isNotEmpty;
  }

  List<LabSchedule> getSchedulesForLocation(String locationId) {
    return _schedulesByLocation[locationId] ?? [];
  }

  Future<void> setSchedulesForLocation(
    String locationId,
    List<LabSchedule> schedules,
  ) async {
    _schedulesByLocation[locationId] = schedules;
    await _save();
    notifyListeners();
  }

  Future<void> updateLabAt(
    String locationId,
    int labIndex,
    LabSchedule lab,
  ) async {
    final labs = List<LabSchedule>.from(getSchedulesForLocation(locationId));
    if (labIndex < 0 || labIndex >= labs.length) return;
    labs[labIndex] = lab;
    _schedulesByLocation[locationId] = labs;
    await _save();
    notifyListeners();
  }

  Future<void> addLab(String locationId, String labName) async {
    final labs = List<LabSchedule>.from(getSchedulesForLocation(locationId));
    labs.add(LabSchedule(labName: labName, entries: []));
    _schedulesByLocation[locationId] = labs;
    await _save();
    notifyListeners();
  }

  Future<void> removeLab(String locationId, int labIndex) async {
    final labs = List<LabSchedule>.from(getSchedulesForLocation(locationId));
    if (labIndex < 0 || labIndex >= labs.length) return;
    labs.removeAt(labIndex);
    if (labs.isEmpty) {
      _schedulesByLocation.remove(locationId);
    } else {
      _schedulesByLocation[locationId] = labs;
    }
    await _save();
    notifyListeners();
  }

  Future<void> ensureLocationExists(String locationId) async {
    if (!_schedulesByLocation.containsKey(locationId)) {
      _schedulesByLocation[locationId] = [];
      await _save();
      notifyListeners();
    }
  }

  Future<void> resetLocationToDefaults(String locationId) async {
    final defaults = DefaultSchedules.all[locationId];
    if (defaults == null) return;
    _schedulesByLocation[locationId] = defaults
        .map(
          (lab) => LabSchedule(
            labName: lab.labName,
            entries: List<ScheduleEntry>.from(lab.entries),
          ),
        )
        .toList();
    await _save();
    notifyListeners();
  }

  bool get isLoaded => _loaded;
}
