import 'package:flutter/material.dart';

/// Clase de profesor para el directorio. Desarrollo Humano e Inglés son
/// clases propias; los profesores de especialidad se agrupan por carrera.
///
/// En Firestore se guarda el [id] en el campo `group` de cada profesor.
enum TeacherGroup {
  itid(
    'itid',
    'Ing. en Tecnologías de la Información e Innovación Digital',
    'ITID',
    Icons.memory_rounded,
    isCareer: true,
  ),
  mecatronica('mecatronica', 'Ing. en Mecatrónica', 'Mecatrónica', Icons.precision_manufacturing_rounded, isCareer: true),
  desarrolloHumano('desarrollo_humano', 'Desarrollo Humano', 'Desarrollo Humano', Icons.diversity_3_rounded),
  ingles('ingles', 'Inglés', 'Inglés', Icons.translate_rounded),
  porAsignar('', 'Por asignar', 'Por asignar', Icons.help_outline_rounded);

  const TeacherGroup(this.id, this.label, this.short, this.icon, {this.isCareer = false});

  /// Valor del campo `group` en Firestore.
  final String id;
  final String label;
  final String short;
  final IconData icon;

  /// Es una carrera (profesores de especialidad).
  final bool isCareer;

  static TeacherGroup fromId(String? id) {
    for (final g in values) {
      if (g.id.isNotEmpty && g.id == id) return g;
    }
    return porAsignar;
  }
}

/// Profesor del directorio. Se guarda en Firestore (`teachers/{id}`), que solo
/// pueden leer cuentas @upjr.edu.mx.
///
/// Campos: `name`, `email`, `group` (ver [TeacherGroup]) y la foto en
/// `photoUrl` (URL) o `imageAsset` (assets/...).
class Contact {
  final String id;
  final String name;

  /// Vacío mientras no se tenga (se muestra "Correo pendiente").
  final String email;
  final TeacherGroup group;

  /// Foto: URL (p. ej. Firebase Storage) o asset de la app. Vacíos si no hay.
  final String photoUrl;
  final String imageAsset;

  const Contact({
    required this.id,
    required this.name,
    this.email = '',
    this.group = TeacherGroup.porAsignar,
    this.photoUrl = '',
    this.imageAsset = '',
  });

  bool get hasEmail => email.trim().isNotEmpty;

  factory Contact.fromMap(String id, Map<String, dynamic> m) => Contact(
        id: id,
        name: m['name'] as String? ?? '',
        email: m['email'] as String? ?? '',
        group: TeacherGroup.fromId(m['group'] as String?),
        photoUrl: m['photoUrl'] as String? ?? '',
        imageAsset: m['imageAsset'] as String? ?? '',
      );
}
