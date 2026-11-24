import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // ← Agregar esta importación
import '../models/contact.dart';
import 'contacts_screen.dart' show TeacherAvatar;
import '../widgets/glass.dart';
import '../widgets/responsive.dart';

class TeacherProfileScreen extends StatelessWidget {
  final Contact teacher;

  const TeacherProfileScreen({super.key, required this.teacher});

  // Función para enviar correo
  Future<void> _sendEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: teacher.email,
      query:
          'subject=Consulta%20desde%20NULLCORE%20MAPS&body=Hola%20profesor%2C',
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      // Si no se puede abrir, mostramos un mensaje
      throw 'No se pudo abrir el cliente de correo';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      forceDark: true,
      backgroundColor: const Color(0xFF1B2230),
      appBar: AppBar(
        title: const Text('Perfil del Profesor'),
        backgroundColor: const Color(0xFF1B2230),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: centeredListPadding(context, horizontal: 24, top: 24, bottom: 24),
        child: Column(
          children: [
            TeacherAvatar(teacher: teacher, radius: 60),
            const SizedBox(height: 16),
            Text(
              teacher.name,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE8A33D).withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                teacher.subject,
                style: const TextStyle(
                  color: Color(0xFFE8A33D),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 32),
            _infoRow(Icons.email, 'Correo', teacher.email),
            _infoRow(Icons.phone, 'Teléfono', teacher.phone.isEmpty ? 'No disponible' : teacher.phone),
            _infoRow(Icons.location_on, 'Oficina', teacher.office.isEmpty ? 'No disponible' : teacher.office),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () async {
                await _sendEmail(); // ← Llamamos a la función de envío
              },
              icon: const Icon(Icons.chat),
              label: const Text('ENVIAR MENSAJE'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFE8A33D),
                side: const BorderSide(color: Color(0xFFE8A33D)),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFE8A33D), size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
