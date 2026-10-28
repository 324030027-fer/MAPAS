import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // ← Agregar esta importación
import 'contacts_screen.dart';

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
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C),
      appBar: AppBar(
        title: const Text('Perfil del Profesor'),
        backgroundColor: const Color(0xFF1E1E2C),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            CircleAvatar(
              radius: 60,
              backgroundImage: AssetImage(teacher.imageAsset),
              backgroundColor: Colors.grey[800],
            ),
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
                color: const Color(0xFF6C63FF).withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                teacher.subject,
                style: const TextStyle(
                  color: Color(0xFF6C63FF),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 32),
            _infoRow(Icons.email, 'Correo', teacher.email),
            _infoRow(Icons.phone, 'Teléfono', teacher.phone),
            _infoRow(Icons.location_on, 'Oficina', teacher.office),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () async {
                await _sendEmail(); // ← Llamamos a la función de envío
              },
              icon: const Icon(Icons.chat),
              label: const Text('ENVIAR MENSAJE'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF00E5FF),
                side: const BorderSide(color: Color(0xFF00E5FF)),
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
          Icon(icon, color: const Color(0xFF00E5FF), size: 24),
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
