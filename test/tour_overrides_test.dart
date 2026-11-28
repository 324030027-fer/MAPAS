import 'package:flutter_test/flutter_test.dart';
import 'package:nullcore_maps/providers/tour_overrides_provider.dart';

void main() {
  test('flechas: guarda el rumbo normalizado y se puede restablecer', () async {
    final o = TourOverridesProvider(syncWithFirestore: false);
    expect(o.linkYaw('ud2', 'CU', 'AUD'), isNull);
    await o.setLinkYaw('ud2', 'CU', 'AUD', 200.04); // 200° = -160°
    expect(o.linkYaw('ud2', 'CU', 'AUD'), -160.0);
    expect(o.linkYaw('ud2', 'AUD', 'CU'), isNull, reason: 'cada sentido es independiente');
    await o.resetLinkYaw('ud2', 'CU', 'AUD');
    expect(o.linkYaw('ud2', 'CU', 'AUD'), isNull);
  });

  test('recuadros: guarda rumbo y altura', () async {
    final o = TourOverridesProvider(syncWithFirestore: false);
    await o.setRoomAnchor('UD2-04', -12.34, 99);
    expect(o.roomAnchor('UD2-04'), (yaw: -12.3, pitch: 60.0));
    await o.resetRoomAnchor('UD2-04');
    expect(o.hasRoomOverride('UD2-04'), isFalse);
  });
}
