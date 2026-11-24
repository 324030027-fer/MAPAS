/// Profesor del directorio. Se guarda en Firestore (`teachers/{id}`), que solo
/// pueden leer cuentas @upjr.edu.mx.
class Contact {
  final String id;
  final String name;
  final String subject;
  final String email;
  final String phone;
  final String office;

  /// Foto dentro de la app (assets/...). Vacía si no hay.
  final String imageAsset;

  const Contact({
    required this.id,
    required this.name,
    required this.subject,
    required this.email,
    this.phone = '',
    this.office = '',
    this.imageAsset = '',
  });

  factory Contact.fromMap(String id, Map<String, dynamic> m) => Contact(
        id: id,
        name: m['name'] as String? ?? '',
        subject: m['subject'] as String? ?? '',
        email: m['email'] as String? ?? '',
        phone: m['phone'] as String? ?? '',
        office: m['office'] as String? ?? '',
        imageAsset: m['imageAsset'] as String? ?? '',
      );
}
