import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/schedule_constants.dart';
import '../../core/utils/schedule_utils.dart';
import '../../models/lab_schedule.dart';
import '../../providers/map_provider.dart';
import '../../providers/schedule_provider.dart';
import '../../widgets/glass.dart';

class ScheduleAdminScreen extends StatefulWidget {
  final bool embedded;

  const ScheduleAdminScreen({super.key, this.embedded = false});

  @override
  State<ScheduleAdminScreen> createState() => _ScheduleAdminScreenState();
}

class _ScheduleAdminScreenState extends State<ScheduleAdminScreen> {
  String? _selectedLocationId;
  int _selectedLabIndex = 0;
  List<ScheduleEntry> _draftEntries = [];
  List<ScheduleEntry>? _undoSnapshot;
  bool _dirty = false;
  String? _dayTableFilter;

  @override
  Widget build(BuildContext context) {
    final mapProvider = context.watch<MapProvider>();
    final scheduleProvider = context.watch<ScheduleProvider>();

    final locationOptions = mapProvider.mapPoints;
    if (_selectedLocationId == null && locationOptions.isNotEmpty) {
      _selectedLocationId = locationOptions.first.id;
      _loadDraft(scheduleProvider);
    }

    final labs = _selectedLocationId == null
        ? <LabSchedule>[]
        : scheduleProvider.getSchedulesForLocation(_selectedLocationId!);

    if (_selectedLabIndex >= labs.length) {
      _selectedLabIndex = labs.isEmpty ? 0 : labs.length - 1;
    }

    final content = Column(
      children: [
        if (widget.embedded && _dirty)
          Material(
            color: AppColors.darkSurface,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text('Cambios sin guardar', style: TextStyle(color: AppColors.highlight)),
                  ),
                  TextButton(onPressed: () => _save(scheduleProvider), child: const Text('GUARDAR')),
                ],
              ),
            ),
          ),
        _buildSelectors(context, mapProvider, scheduleProvider, labs),
        if (_dayTableFilter != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: InputChip(
                label: Text('Día: $_dayTableFilter'),
                onDeleted: () => setState(() => _dayTableFilter = null),
              ),
            ),
          ),
        Expanded(child: _buildTable()),
      ],
    );

    if (widget.embedded) {
      return ColoredBox(color: AppColors.darkBg, child: content);
    }

    return GlassScaffold(
      forceDark: true,
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: const Text('Horarios de laboratorios'),
        backgroundColor: AppColors.darkBg,
        foregroundColor: Colors.white,
        actions: [
          if (_dirty)
            TextButton.icon(
              onPressed: () => _save(scheduleProvider),
              icon: const Icon(Icons.save, color: AppColors.highlight),
              label: const Text(
                'GUARDAR',
                style: TextStyle(color: AppColors.highlight, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: content,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addRow,
        backgroundColor: AppColors.highlight,
        icon: const Icon(Icons.add, color: Colors.black),
        label: const Text('Nueva fila', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildSelectors(
    BuildContext context,
    MapProvider mapProvider,
    ScheduleProvider scheduleProvider,
    List<LabSchedule> labs,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFF2D2D44),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Edificio', style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: _selectedLocationId,
            dropdownColor: const Color(0xFF2D2D44),
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration(),
            items: mapProvider.mapPoints
                .map(
                  (loc) => DropdownMenuItem(
                    value: loc.id,
                    child: Text(loc.title),
                  ),
                )
                .toList(),
            onChanged: (value) async {
              if (value == null) return;
              if (_dirty && !await _confirmDiscard()) return;
              setState(() {
                _selectedLocationId = value;
                _selectedLabIndex = 0;
              });
              await scheduleProvider.ensureLocationExists(value);
              _loadDraft(scheduleProvider);
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Laboratorio', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<int>(
                      initialValue: labs.isEmpty ? null : _selectedLabIndex,
                      dropdownColor: const Color(0xFF2D2D44),
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration(),
                      items: labs.asMap().entries.map((e) {
                        return DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value.labName),
                        );
                      }).toList(),
                      onChanged: labs.isEmpty
                          ? null
                          : (index) async {
                              if (index == null) return;
                              if (_dirty && !await _confirmDiscard()) return;
                              setState(() => _selectedLabIndex = index);
                              _loadDraft(scheduleProvider);
                            },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Nuevo laboratorio',
                onPressed: _selectedLocationId == null
                    ? null
                    : () => _showNewLabDialog(scheduleProvider),
                icon: const Icon(Icons.add_circle_outline, color: Color(0xFF00E5FF)),
              ),
              if (labs.isNotEmpty)
                IconButton(
                  tooltip: 'Eliminar laboratorio',
                  onPressed: () => _deleteLab(scheduleProvider),
                  icon: const Icon(Icons.delete_outline, color: Color(0xFFFF2E63)),
                ),
            ],
          ),
          if (kDefaultScheduleLocationIds.contains(_selectedLocationId))
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TextButton.icon(
                onPressed: () => _resetDefaults(scheduleProvider),
                icon: const Icon(Icons.restore, size: 18, color: Colors.white54),
                label: const Text(
                  'Restaurar horarios originales de este edificio',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ),
            ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            children: [
              ActionChip(
                label: const Text('Todos los días', style: TextStyle(fontSize: 11)),
                onPressed: () => setState(() => _dayTableFilter = null),
              ),
              ...kWeekDays.map(
                (d) => ActionChip(
                  label: Text(d, style: const TextStyle(fontSize: 11)),
                  onPressed: () => setState(() => _dayTableFilter = d),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTable() {
    if (_selectedLocationId == null) {
      return const Center(child: Text('Selecciona un edificio', style: TextStyle(color: Colors.white54)));
    }

    if (_draftEntries.isEmpty) {
      return const Center(
        child: Text(
          'Sin clases registradas.\nPulsa "Nueva fila" para agregar.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    final visibleRows = _draftEntries.asMap().entries.where((row) {
      if (_dayTableFilter == null) return true;
      return row.value.day == _dayTableFilter;
    }).toList();

    return Stack(
      children: [
        SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(12, 8, 12, widget.embedded ? 72 : 80),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(AppColors.darkSurface),
              dataRowMinHeight: 56,
              dataRowMaxHeight: 72,
              headingTextStyle: const TextStyle(
                color: AppColors.highlight,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
              columns: const [
                DataColumn(label: Text('DÍA')),
                DataColumn(label: Text('INICIO')),
                DataColumn(label: Text('FIN')),
                DataColumn(label: Text('MATERIA')),
                DataColumn(label: Text('GRUPO')),
                DataColumn(label: Text('PROFESOR')),
                DataColumn(label: Text('')),
              ],
              rows: visibleRows.map((row) {
                final index = row.key;
                final entry = row.value;
                final invalidTime = !isValidTimeRange(entry.startTime, entry.endTime);
                return DataRow(
                  color: invalidTime
                      ? WidgetStateProperty.all(AppColors.danger.withValues(alpha: 0.12))
                      : null,
                  cells: [
                    DataCell(_dayDropdown(index, entry)),
                    DataCell(_timeField(index, entry, isStart: true)),
                    DataCell(_timeField(index, entry, isStart: false)),
                    DataCell(_textField(index, entry, field: _Field.subject)),
                    DataCell(_textField(index, entry, field: _Field.group)),
                    DataCell(_textField(index, entry, field: _Field.teacher)),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.copy, color: AppColors.accent, size: 20),
                            tooltip: 'Duplicar fila',
                            onPressed: () => _duplicateRow(index),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                            onPressed: () => _removeRow(index),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
        if (widget.embedded)
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton.extended(
              onPressed: _addRow,
              backgroundColor: AppColors.highlight,
              icon: const Icon(Icons.add, color: Colors.black),
              label: const Text('Fila', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ),
      ],
    );
  }

  void _duplicateRow(int index) {
    setState(() {
      _draftEntries.insert(index + 1, _draftEntries[index].copyWith());
      _dirty = true;
    });
  }

  Widget _dayDropdown(int index, ScheduleEntry entry) {
    return SizedBox(
      width: 110,
      child: DropdownButton<String>(
        value: kWeekDays.contains(entry.day) ? entry.day : kWeekDays.first,
        isExpanded: true,
        dropdownColor: const Color(0xFF2D2D44),
        style: const TextStyle(color: Colors.white, fontSize: 12),
        items: kWeekDays.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
        onChanged: (day) {
          if (day == null) return;
          _updateEntry(index, entry.copyWith(day: day));
        },
      ),
    );
  }

  Widget _timeField(int index, ScheduleEntry entry, {required bool isStart}) {
    final controller = TextEditingController(
      text: isStart ? entry.startTime : entry.endTime,
    );
    return SizedBox(
      width: 72,
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white, fontSize: 12),
        decoration: _cellDecoration(hint: '08:00'),
        onChanged: (value) {
          _updateEntry(
            index,
            isStart ? entry.copyWith(startTime: value) : entry.copyWith(endTime: value),
          );
        },
      ),
    );
  }

  Widget _textField(int index, ScheduleEntry entry, {required _Field field}) {
    String text;
    switch (field) {
      case _Field.subject:
        text = entry.subject;
      case _Field.group:
        text = entry.group;
      case _Field.teacher:
        text = entry.teacher;
    }

    final width = field == _Field.subject ? 180.0 : 120.0;
    final controller = TextEditingController(text: text);

    return SizedBox(
      width: width,
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white, fontSize: 12),
        decoration: _cellDecoration(),
        onChanged: (value) {
          switch (field) {
            case _Field.subject:
              _updateEntry(index, entry.copyWith(subject: value));
            case _Field.group:
              _updateEntry(index, entry.copyWith(group: value));
            case _Field.teacher:
              _updateEntry(index, entry.copyWith(teacher: value));
          }
        },
      ),
    );
  }

  void _loadDraft(ScheduleProvider provider) {
    final locationId = _selectedLocationId;
    if (locationId == null) return;
    final labs = provider.getSchedulesForLocation(locationId);
    if (labs.isEmpty) {
      setState(() {
        _draftEntries = [];
        _dirty = false;
      });
      return;
    }
    final lab = labs[_selectedLabIndex.clamp(0, labs.length - 1)];
    setState(() {
      _draftEntries = lab.entries.map((e) => e.copyWith()).toList();
      _dirty = false;
    });
  }

  void _updateEntry(int index, ScheduleEntry entry) {
    setState(() {
      _draftEntries[index] = entry;
      _dirty = true;
    });
  }

  void _addRow() {
    setState(() {
      _draftEntries.add(
        ScheduleEntry(
          day: kWeekDays.first,
          startTime: '08:00',
          endTime: '08:50',
          subject: '',
          group: '',
          teacher: '',
        ),
      );
      _dirty = true;
    });
  }

  void _removeRow(int index) {
    setState(() {
      _draftEntries.removeAt(index);
      _dirty = true;
    });
  }

  Future<void> _save(ScheduleProvider provider) async {
    final locationId = _selectedLocationId;
    if (locationId == null) return;

    for (final entry in _draftEntries) {
      if (!isValidTimeRange(entry.startTime, entry.endTime)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hora inválida en "${entry.subject}": ${entry.startTime} - ${entry.endTime}'),
            backgroundColor: AppColors.danger,
          ),
        );
        return;
      }
    }

    final labs = List<LabSchedule>.from(provider.getSchedulesForLocation(locationId));
    if (labs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Crea un laboratorio primero')),
      );
      return;
    }

    _undoSnapshot = labs[_selectedLabIndex].entries.map((e) => e.copyWith()).toList();

    labs[_selectedLabIndex] = labs[_selectedLabIndex].copyWith(entries: _draftEntries);
    await provider.setSchedulesForLocation(locationId, labs);

    setState(() => _dirty = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Horarios guardados'),
        backgroundColor: AppColors.accent,
        action: SnackBarAction(
          label: 'Deshacer',
          textColor: Colors.white,
          onPressed: () async {
            if (_undoSnapshot == null) return;
            final undoLabs = List<LabSchedule>.from(provider.getSchedulesForLocation(locationId));
            undoLabs[_selectedLabIndex] =
                undoLabs[_selectedLabIndex].copyWith(entries: _undoSnapshot!);
            await provider.setSchedulesForLocation(locationId, undoLabs);
            _loadDraft(provider);
          },
        ),
      ),
    );
  }

  Future<void> _showNewLabDialog(ScheduleProvider provider) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D44),
        title: const Text('Nuevo laboratorio', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Nombre del laboratorio',
            labelStyle: TextStyle(color: Colors.white70),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFFF8C00)),
            child: const Text('Crear'),
          ),
        ],
      ),
    );

    if (name == null || name.isEmpty || _selectedLocationId == null) return;
    await provider.ensureLocationExists(_selectedLocationId!);
    await provider.addLab(_selectedLocationId!, name);
    setState(() {
      _selectedLabIndex = provider.getSchedulesForLocation(_selectedLocationId!).length - 1;
      _draftEntries = [];
      _dirty = false;
    });
  }

  Future<void> _deleteLab(ScheduleProvider provider) async {
    final locationId = _selectedLocationId;
    if (locationId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D44),
        title: const Text('¿Eliminar laboratorio?', style: TextStyle(color: Colors.white)),
        content: const Text('Se borrarán todas las filas de horario.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFFF2E63)),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    await provider.removeLab(locationId, _selectedLabIndex);
    _loadDraft(provider);
  }

  Future<void> _resetDefaults(ScheduleProvider provider) async {
    final locationId = _selectedLocationId;
    if (locationId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D44),
        title: const Text('Restaurar horarios', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Se reemplazarán los horarios de este edificio con los valores originales.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Restaurar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    await provider.resetLocationToDefaults(locationId);
    _loadDraft(provider);
  }

  Future<bool> _confirmDiscard() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D44),
        title: const Text('Cambios sin guardar', style: TextStyle(color: Colors.white)),
        content: const Text('¿Descartar los cambios?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Descartar')),
        ],
      ),
    );
    if (discard == true) setState(() => _dirty = false);
    return discard == true;
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFF1E1E2C),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white24),
      ),
    );
  }

  InputDecoration _cellDecoration({String? hint}) {
    return InputDecoration(
      isDense: true,
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white38, fontSize: 11),
      filled: true,
      fillColor: const Color(0xFF1E1E2C),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    );
  }
}

enum _Field { subject, group, teacher }
