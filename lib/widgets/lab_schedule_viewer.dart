import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/schedule_utils.dart';
import '../models/lab_schedule.dart';

class LabScheduleViewer extends StatefulWidget {
  final List<LabSchedule> schedules;

  const LabScheduleViewer({super.key, required this.schedules});

  @override
  State<LabScheduleViewer> createState() => _LabScheduleViewerState();
}

class _LabScheduleViewerState extends State<LabScheduleViewer> {
  late LabSchedule _selectedSchedule;
  late String _selectedDay;
  final List<String> _days = ["Lunes", "Martes", "Miércoles", "Jueves", "Viernes"];

  @override
  void initState() {
    super.initState();
    _selectedSchedule = widget.schedules.first;
    _selectedDay = _days.first;
  }

  @override
  Widget build(BuildContext context) {
    final entriesForDay = _selectedSchedule.entries
        .where((e) => e.day == _selectedDay)
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Selector de laboratorio (Chips horizontales)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: widget.schedules.map((schedule) {
              final isSelected = _selectedSchedule.labName == schedule.labName;
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: FilterChip(
                  label: Text(schedule.labName),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedSchedule = schedule;
                      });
                    }
                  },
                  selectedColor: const Color(0xFFFF8C00), // Naranja vibrante
                  backgroundColor: const Color(0xFF1E1E2C),
                  checkmarkColor: Colors.white,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 20),

        // Selector de día (pestañas horizontales)
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E2C),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            children: _days.map((day) {
              final isSelected = _selectedDay == day;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedDay = day),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFFF8C00) : Colors.transparent,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      day,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 20),

        // Lista de horarios del día seleccionado
        if (entriesForDay.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Text(
                "No hay clases programadas\nen este laboratorio para este día.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: entriesForDay.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (ctx, index) {
              final entry = entriesForDay[index];
              return _buildScheduleCard(entry);
            },
          ),
      ],
    );
  }

  Widget _buildScheduleCard(ScheduleEntry entry) {
    final now = isScheduleEntryNow(entry);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(20),
        border: now ? Border.all(color: AppColors.highlight, width: 1.5) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 70,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.darkBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    entry.startTime,
                    style: TextStyle(
                      color: now ? AppColors.highlight : AppColors.highlight,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const Text('a', style: TextStyle(color: Colors.white54, fontSize: 10)),
                  Text(
                    entry.endTime,
                    style: const TextStyle(
                      color: AppColors.highlight,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.subject,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (now)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.highlight.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'EN CURSO',
                            style: TextStyle(
                              color: AppColors.highlight,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.highlight.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          entry.group,
                          style: const TextStyle(
                            color: AppColors.highlight,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          entry.teacher,
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}