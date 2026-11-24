import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nullcore_maps/models/map_location.dart';
import 'package:nullcore_maps/providers/map_provider.dart';
import 'package:nullcore_maps/screens/admin/new_location_screen.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('Nueva ubicación: tocar el mapa y guardar llena ID y coordenadas', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final provider = MapProvider(syncWithFirestore: false);
    final before = provider.mapPoints.length;
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: provider,
      child: MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NewLocationScreen())),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    // Sin punto: no guarda y avisa.
    await tester.tap(find.text('Guardar'));
    await tester.pump();
    expect(find.text('Toca el mapa para elegir dónde va la ubicación'), findsOneWidget);
    await tester.pumpAndSettle(const Duration(seconds: 5));

    // Toca el centro del mapa.
    final map = find.byType(InteractiveViewer);
    await tester.tapAt(tester.getCenter(map));
    await tester.pump();
    expect(find.textContaining('Posición: X 0.500'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, 'Nombre'), 'Sala de juntas');
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Servicios').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Baños'));
    await tester.pump();

    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(provider.mapPoints.length, before + 1);
    final nuevo = provider.mapPoints.last;
    expect(nuevo.id, 'SALA_DE_JUNTAS');
    expect(nuevo.title, 'SALA DE JUNTAS');
    expect(nuevo.category, 'Servicios');
    expect(nuevo.icon, Icons.wc);
    expect(nuevo.x, closeTo(0.5, 0.01));
    expect(nuevo.y, closeTo(0.5, 0.01));
    // El ícono sobrevive a guardarse y leerse (como pasa con Firestore).
    expect(MapLocation.fromJson(nuevo.toJson()).icon, Icons.wc);
  });
}
