import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../data/building_outlines.dart' show kShortNames;
import '../data/rooms.dart';
import '../data/tours/tours.dart';
import '../models/room.dart';
import '../models/tour.dart';
import '../screens/panorama_viewer.dart';

/// Abre el salón en 360°. Si es parada del recorrido del edificio, entra al
/// recorrido en ese punto (se puede seguir caminando); si no, solo su
/// panorama. Sin foto todavía, avisa y no abre nada.
void openRoom(BuildContext context, Room room, {bool replace = false}) {
  if (!room.has360) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text('La foto 360° de ${room.name} estará disponible pronto.'),
        behavior: SnackBarBehavior.floating,
      ));
    return;
  }
  final tour = room.tourStopId == null ? null : tourForMapLocation(room.buildingId);
  final viewer = tour != null
      ? PanoramaViewer(tour: tour, startId: room.tourStopId, room: room)
      : PanoramaViewer(
          tour: Tour.single(title: room.name, asset: room.pano!),
          initialYaw: room.initialYaw,
          room: room,
        );
  final route = replace
      ? PageRouteBuilder<void>(
          pageBuilder: (_, __, ___) => viewer,
          transitionDuration: const Duration(milliseconds: 180),
          transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
        )
      : MaterialPageRoute<void>(builder: (_) => viewer);
  final nav = Navigator.of(context);
  replace ? nav.pushReplacement(route) : nav.push(route);
}

/// Hoja inferior con el selector de salones de un edificio.
Future<void> showRoomPickerSheet(BuildContext context, String buildingId, {String? currentRoomId, bool replace = false}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.darkCard,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (sheetContext) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.62,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      builder: (_, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Text(
            'Salones de ${kShortNames[buildingId] ?? buildingId}',
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          RoomPicker(
            buildingId: buildingId,
            forceDark: true,
            currentRoomId: currentRoomId,
            onPick: (room) {
              Navigator.pop(sheetContext);
              openRoom(context, room, replace: replace);
            },
          ),
        ],
      ),
    ),
  );
}

/// Colores del selector según el fondo (la hoja del mapa siempre es oscura).
class _Palette {
  _Palette(bool dark)
      : fg = dark ? Colors.white : AppColors.textPrimaryLight,
        muted = dark ? Colors.white54 : AppColors.textSecondaryLight,
        surface = dark ? Colors.white.withValues(alpha: 0.07) : Colors.white.withValues(alpha: 0.75),
        border = dark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.08),
        accentText = dark ? AppColors.accent : AppColors.accentOnLight;
  final Color fg, muted, surface, border, accentText;
}

/// Selector rápido de salones: buscador por número o nombre, filtro por planta
/// y una cuadrícula de botones numerados (como un tablero de elevador).
///
/// Un toque entra directo al panorama del salón; no hace falta recorrer el
/// edificio desde la entrada.
class RoomPicker extends StatefulWidget {
  const RoomPicker({
    super.key,
    required this.buildingId,
    this.forceDark = false,
    this.currentRoomId,
    this.onPick,
  });

  final String buildingId;
  final bool forceDark;
  final String? currentRoomId;

  /// Por defecto abre el salón con [openRoom].
  final ValueChanged<Room>? onPick;

  @override
  State<RoomPicker> createState() => _RoomPickerState();
}

class _RoomPickerState extends State<RoomPicker> {
  final _search = TextEditingController();
  String _query = '';
  String? _floor; // null = todas

  @override
  void didUpdateWidget(RoomPicker old) {
    super.didUpdateWidget(old);
    if (old.buildingId != widget.buildingId) {
      _search.clear();
      _query = '';
      _floor = null;
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _pick(Room r) => widget.onPick != null ? widget.onPick!(r) : openRoom(context, r);

  @override
  Widget build(BuildContext context) {
    final dark = widget.forceDark || Theme.of(context).brightness == Brightness.dark;
    final p = _Palette(dark);
    final all = roomsOf(widget.buildingId);
    final floors = [for (final r in all) r.floor].where((f) => f.isNotEmpty).toSet().toList();
    final ready = all.where((r) => r.has360).length;

    final searching = _query.isNotEmpty;
    final shown = searching
        ? searchRooms(_query, from: all)
        : all.where((r) => _floor == null || r.floor == _floor).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Buscador
        Container(
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: p.border),
          ),
          child: TextField(
            controller: _search,
            onChanged: (v) => setState(() => _query = v.trim()),
            textInputAction: TextInputAction.search,
            onSubmitted: (_) {
              final hits = searchRooms(_query, from: all);
              if (hits.length == 1 || (hits.isNotEmpty && hits.first.label == _query)) _pick(hits.first);
            },
            style: TextStyle(color: p.fg, fontSize: 15),
            decoration: InputDecoration(
              hintText: 'Número o nombre (ej. 7, Móviles)',
              hintStyle: TextStyle(color: p.muted, fontSize: 14),
              prefixIcon: Icon(Icons.search_rounded, color: p.accentText),
              suffixIcon: searching
                  ? IconButton(
                      tooltip: 'Borrar',
                      icon: Icon(Icons.close_rounded, color: p.muted, size: 20),
                      onPressed: () {
                        _search.clear();
                        setState(() => _query = '');
                      },
                    )
                  : null,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Filtro de planta
        if (!searching && floors.length > 1) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _FloorChip(label: 'Todas', selected: _floor == null, palette: p, onTap: () => setState(() => _floor = null)),
              for (final f in floors)
                _FloorChip(
                  label: floorName(f),
                  selected: _floor == f,
                  palette: p,
                  onTap: () => setState(() => _floor = f),
                ),
            ],
          ),
          const SizedBox(height: 14),
        ],
        if (shown.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Text(
              searching ? 'No hay un salón "$_query" en ${kShortNames[widget.buildingId] ?? widget.buildingId}.' : 'Sin salones registrados.',
              style: TextStyle(color: p.muted),
            ),
          )
        else if (searching || _floor != null || floors.length <= 1)
          _RoomGrid(rooms: shown, palette: p, currentId: widget.currentRoomId, onPick: _pick)
        else
          for (final f in floors) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8, left: 2),
              child: Text(
                floorName(f).toUpperCase(),
                style: TextStyle(color: p.muted, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.3),
              ),
            ),
            _RoomGrid(
              rooms: shown.where((r) => r.floor == f).toList(),
              palette: p,
              currentId: widget.currentRoomId,
              onPick: _pick,
            ),
            const SizedBox(height: 14),
          ],
        // Leyenda
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Icon(Icons.threesixty_rounded, size: 15, color: p.accentText),
              const SizedBox(width: 4),
              Text('360° disponible', style: TextStyle(color: p.muted, fontSize: 11.5)),
              const SizedBox(width: 14),
              Icon(Icons.hourglass_empty_rounded, size: 14, color: p.muted),
              const SizedBox(width: 4),
              Text('Foto pendiente', style: TextStyle(color: p.muted, fontSize: 11.5)),
              const Spacer(),
              Text('$ready de ${all.length} listos', style: TextStyle(color: p.muted, fontSize: 11.5)),
            ],
          ),
        ),
      ],
    );
  }
}

class _FloorChip extends StatelessWidget {
  const _FloorChip({required this.label, required this.selected, required this.palette, required this.onTap});
  final String label;
  final bool selected;
  final _Palette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.accent : palette.surface,
      shape: StadiumBorder(side: BorderSide(color: selected ? AppColors.accent : palette.border)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? AppColors.onAccent : palette.fg,
              fontSize: 12.5,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _RoomGrid extends StatelessWidget {
  const _RoomGrid({required this.rooms, required this.palette, required this.onPick, this.currentId});
  final List<Room> rooms;
  final _Palette palette;
  final ValueChanged<Room> onPick;
  final String? currentId;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [for (final r in rooms) _RoomTile(room: r, palette: palette, current: r.id == currentId, onTap: () => onPick(r))],
    );
  }
}

class _RoomTile extends StatelessWidget {
  const _RoomTile({required this.room, required this.palette, required this.onTap, this.current = false});
  final Room room;
  final _Palette palette;
  final VoidCallback onTap;
  final bool current;

  @override
  Widget build(BuildContext context) {
    final ready = room.has360;
    final p = palette;
    final numbered = room.isNumbered;
    final borderColor = current
        ? AppColors.accent
        : ready
            ? AppColors.accent.withValues(alpha: 0.55)
            : p.border;

    final content = numbered
        ? Text(
            room.label,
            style: TextStyle(
              color: ready ? p.fg : p.muted,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(room.kind.icon, size: 18, color: ready ? p.accentText : p.muted),
              const SizedBox(width: 8),
              Text(
                room.label,
                style: TextStyle(color: ready ? p.fg : p.muted, fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ],
          );

    return Tooltip(
      message: ready ? '${room.name} · ver en 360°' : '${room.name} · foto pendiente',
      child: Semantics(
        button: true,
        label: ready ? room.name : '${room.name}, foto pendiente',
        child: Material(
          color: current ? AppColors.accent.withValues(alpha: 0.22) : p.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: borderColor, width: current ? 2 : 1),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: SizedBox(
              height: 58,
              width: numbered ? 58 : null,
              child: Stack(
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: numbered ? 0 : 16),
                    child: Center(widthFactor: numbered ? null : 1, child: content),
                  ),
                  Positioned(
                    top: 5,
                    right: 6,
                    child: Icon(
                      ready ? Icons.threesixty_rounded : Icons.hourglass_empty_rounded,
                      size: ready ? 13 : 11,
                      color: ready ? p.accentText : p.muted.withValues(alpha: 0.7),
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

/// Barra del visor 360° cuando se entró a un salón: anterior / elegir otro /
/// siguiente, dentro del mismo edificio y solo entre salones con foto.
class RoomSwitcherBar extends StatelessWidget {
  const RoomSwitcherBar({super.key, required this.room});
  final Room room;

  @override
  Widget build(BuildContext context) {
    final list = roomsOf(room.buildingId).where((r) => r.has360).toList();
    final i = list.indexWhere((r) => r.id == room.id);
    final prev = i > 0 ? list[i - 1] : null;
    final next = i >= 0 && i < list.length - 1 ? list[i + 1] : null;
    final building = kShortNames[room.buildingId] ?? room.buildingId;

    Widget arrow(IconData icon, Room? target, String tip) => IconButton(
          tooltip: target == null ? null : '$tip: ${target.name}',
          onPressed: target == null ? null : () => openRoom(context, target, replace: true),
          icon: Icon(icon),
          color: Colors.white,
          disabledColor: Colors.white24,
        );

    return Container(
      constraints: const BoxConstraints(maxWidth: 420),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          arrow(Icons.chevron_left_rounded, prev, 'Anterior'),
          Flexible(
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () => showRoomPickerSheet(context, room.buildingId, currentRoomId: room.id, replace: true),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.grid_view_rounded, color: AppColors.accent, size: 18),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            room.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w800),
                          ),
                          Text(
                            [building, if (room.floor.isNotEmpty) floorName(room.floor), 'Cambiar salón'].join(' · '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white60, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          arrow(Icons.chevron_right_rounded, next, 'Siguiente'),
        ],
      ),
    );
  }
}

/// Resultados de salones para el buscador del mapa ("salón 7", "ud2 7"...).
class RoomSearchResults extends StatelessWidget {
  const RoomSearchResults({super.key, required this.query, this.max = 4});
  final String query;
  final int max;

  @override
  Widget build(BuildContext context) {
    final hits = searchRooms(query);
    if (hits.isEmpty) return const SizedBox.shrink();
    final dark = Theme.of(context).brightness == Brightness.dark;
    final p = _Palette(dark);
    final shown = hits.take(max).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
          child: Text(
            'SALONES',
            style: TextStyle(color: p.muted, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.4),
          ),
        ),
        for (final r in shown)
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => openRoom(context, r),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: r.has360 ? 0.22 : 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: r.isNumbered
                          ? Text(r.label, style: TextStyle(color: p.fg, fontWeight: FontWeight.w800))
                          : Icon(r.kind.icon, size: 18, color: p.accentText),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.name, style: TextStyle(color: p.fg, fontWeight: FontWeight.w700, fontSize: 13.5)),
                          Text(
                            [kShortNames[r.buildingId] ?? r.buildingId, if (r.floor.isNotEmpty) floorName(r.floor)].join(' · '),
                            style: TextStyle(color: p.muted, fontSize: 11.5),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      r.has360 ? Icons.threesixty_rounded : Icons.hourglass_empty_rounded,
                      size: 18,
                      color: r.has360 ? p.accentText : p.muted,
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (hits.length > shown.length)
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 2, 8, 0),
            child: Text('y ${hits.length - shown.length} más…', style: TextStyle(color: p.muted, fontSize: 11.5)),
          ),
      ],
    );
  }
}
