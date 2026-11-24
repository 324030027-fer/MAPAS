import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nullcore_maps/providers/map_provider.dart';
import 'package:nullcore_maps/screens/admin/map_pin_editor_screen.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('Editor de pines: mover no guarda hasta presionar Guardar', (tester) async {
    tester.view.physicalSize = const Size(1360, 680);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final provider = MapProvider(syncWithFirestore: false);
    final original = provider.mapPoints.first;
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: provider,
      child: const MaterialApp(home: Scaffold(body: MapPinEditorScreen(embedded: true))),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Sin cambios'), findsOneWidget);

    // Selecciona LT en la lista y toca otro punto del mapa.
    await tester.tap(find.widgetWithText(ListTile, original.title));
    await tester.pump();
    await tester.tapAt(tester.getCenter(find.byType(InteractiveViewer)));
    await tester.pump();

    expect(find.text('1 cambio sin guardar'), findsOneWidget);
    expect(provider.mapPoints.firstWhere((l) => l.id == original.id).x, original.x,
        reason: 'No debe guardarse antes de presionar Guardar');

    // Descartar regresa todo.
    await tester.tap(find.text('Descartar'));
    await tester.pump();
    expect(find.text('Sin cambios'), findsOneWidget);

    // Mover otra vez y guardar.
    await tester.tapAt(tester.getCenter(find.byType(InteractiveViewer)));
    await tester.pump();
    await tester.tap(find.text('Guardar'));
    await tester.pump();
    final moved = provider.mapPoints.firstWhere((l) => l.id == original.id);
    expect(moved.x, closeTo(0.5, 0.02));
    expect(moved.y, closeTo(0.5, 0.02));
    expect(find.text('Sin cambios'), findsOneWidget);
  });
}
