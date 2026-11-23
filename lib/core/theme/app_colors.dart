import 'package:flutter/material.dart';

/// Paleta "Pizarra y ámbar" de NULLCORE MAPS / UPJR Campus.
///
/// Un solo color de acento (ámbar, cercano al naranja del logo UPJR) sobre
/// fondos azul pizarra. Sin neones: el ámbar marca lo importante y todo lo
/// demás es neutro.
abstract final class AppColors {
  /// Ámbar: botones, selección, chips activos, íconos de acento.
  static const primary = Color(0xFFE8A33D);
  static const accent = Color(0xFFE8A33D);

  /// Ámbar claro para resaltar (selección en el mapa, avisos "en curso").
  static const highlight = Color(0xFFF0BC66);

  /// Texto e íconos SOBRE un relleno ámbar (el blanco no se lee).
  static const onAccent = Color(0xFF2B1D06);

  /// Ámbar oscuro para texto/íconos de acento en modo claro.
  static const accentOnLight = Color(0xFF9A6412);

  static const danger = Color(0xFFE5484D);
  static const admin = Color(0xFFD9822B);

  static const darkBg = Color(0xFF1B2230);
  static const darkSurface = Color(0xFF263042);
  static const darkCard = Color(0xFF222B3A);

  static const lightBg = Color(0xFFF3F4F6);
  static const lightSurface = Colors.white;

  static const textPrimaryDark = Color(0xFFF2F4F7);
  static const textSecondaryDark = Color(0x9EF2F4F7);
  static const textPrimaryLight = Color(0xFF1B2230);
  static const textSecondaryLight = Color(0xFF5B6472);
}
