import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/schedule_constants.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/schedule_utils.dart';
import '../providers/map_provider.dart';
import '../providers/schedule_provider.dart';
import '../widgets/empty_state.dart';
import '../models/lab_schedule.dart';

class GlobalScheduleSearchScreen extends StatefulWidget {
  const GlobalScheduleSearchScreen({super.key});

  @override
  State<GlobalScheduleSearchScreen> createState() => _GlobalScheduleSearchScreenState();
}

class _GlobalScheduleSearchScreenState extends State<GlobalScheduleSearchScreen> {
  final _controller = TextEditingController();
  String _query = '';
  String? _dayFilter;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheduleProvider = context.watch<ScheduleProvider>();
    final mapProvider = context.watch<MapProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final results = _search(scheduleProvider, mapProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      appBar: AppBar(
        title: const Text('Buscar horarios'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _controller,
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Materia, profesor, grupo, laboratorio…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _controller.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
              ),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _dayChip('Todos', null),
                ...kWeekDays.map((d) => _dayChip(d, d)),
              ],
            ),
          ),
          Expanded(
            child: results.isEmpty
                ? EmptyState(
                    icon: Icons.event_busy,
                    title: _query.isEmpty ? 'Escribe para buscar' : 'Sin resultados',
                    subtitle: _query.isEmpty
                        ? 'Encuentra clases por materia, profesor o grupo en todo el campus.'
                        : 'Prueba otro término o quita el filtro de día.',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: results.length,
                    itemBuilder: (context, i) {
                      final r = results[i];
                      final now = isScheduleEntryNow(r.entry);
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        color: isDark ? AppColors.darkSurface : Colors.white,
                        child: ListTile(
                          leading: Container(
                            width: 52,
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkBg : AppColors.lightBg,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  r.entry.startTime,
                                  style: TextStyle(
                                    color: now ? AppColors.highlight : AppColors.accent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          title: Text(
                            r.entry.subject,
                            style: TextStyle(
                              color: isDark ? Colors.white : AppColors.textPrimaryLight,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            '${r.entry.day} · ${r.entry.startTime}-${r.entry.endTime}\n'
                            '${r.entry.teacher} · ${r.entry.group}\n'
                            '${r.buildingTitle} · ${r.labName}',
                            style: TextStyle(
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              fontSize: 12,
                              height: 1.35,
                            ),
                          ),
                          isThreeLine: true,
                          trailing: now
                              ? Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.highlight.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'AHORA',
                                    style: TextStyle(color: AppColors.highlight, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                )
                              : null,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _dayChip(String label, String? value) {
    final selected = _dayFilter == value || (value == null && _dayFilter == null);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selected: selected,
        onSelected: (_) => setState(() => _dayFilter = value),
      ),
    );
  }

  List<_SearchResult> _search(ScheduleProvider schedules, MapProvider map) {
    final results = <_SearchResult>[];
    for (final locationId in schedules.locationIdsWithSchedules) {
      final buildingTitle = map.mapPoints.where((l) => l.id == locationId).map((l) => l.title).firstOrNull ?? locationId;
      for (final lab in schedules.getSchedulesForLocation(locationId)) {
        for (final entry in lab.entries) {
          if (_dayFilter != null && entry.day != _dayFilter) continue;
          if (_query.isNotEmpty) {
            final haystack =
                '${entry.subject} ${entry.teacher} ${entry.group} ${lab.labName} $buildingTitle'.toLowerCase();
            if (!haystack.contains(_query)) continue;
          } else if (_dayFilter == null) {
            continue;
          }
          results.add(_SearchResult(
            entry: entry,
            labName: lab.labName,
            buildingTitle: buildingTitle,
            locationId: locationId,
          ));
        }
      }
    }
    results.sort((a, b) {
      final dayCmp = kWeekDays.indexOf(a.entry.day).compareTo(kWeekDays.indexOf(b.entry.day));
      if (dayCmp != 0) return dayCmp;
      return a.entry.startTime.compareTo(b.entry.startTime);
    });
    return results;
  }
}

class _SearchResult {
  final ScheduleEntry entry;
  final String labName;
  final String buildingTitle;
  final String locationId;

  _SearchResult({
    required this.entry,
    required this.labName,
    required this.buildingTitle,
    required this.locationId,
  });
}
