import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/contact.dart';
import '../providers/private_data_provider.dart';
import 'teacher_profile_screen.dart';
import '../widgets/glass.dart';
import '../widgets/responsive.dart';

class ContactsScreen extends StatelessWidget {
  const ContactsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<PrivateDataProvider>();
    final teachers = data.teachers;
    return GlassScaffold(
      forceDark: true,
      backgroundColor: const Color(0xFF1B2230),
      appBar: AppBar(
        title: const Text('Contactos'),
        backgroundColor: const Color(0xFF1B2230),
        foregroundColor: Colors.white,
      ),
      body: teachers.isEmpty
          ? Center(
              child: data.loaded
                  ? const Text('Aún no hay profesores registrados.', style: TextStyle(color: Colors.white70))
                  : const CircularProgressIndicator(),
            )
          : ListView.builder(
        padding: centeredListPadding(context, horizontal: 0, top: 8, bottom: 24),
        itemCount: teachers.length,
        itemBuilder: (ctx, index) {
          final teacher = teachers[index];
          return GlassCard(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: TeacherAvatar(teacher: teacher, radius: 20),
              title: Text(
                teacher.name,
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                teacher.subject,
                style: const TextStyle(color: Colors.white70),
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                color: Color(0xFFE8A33D),
                size: 16,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TeacherProfileScreen(teacher: teacher),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

/// Foto del profesor o, si no hay, sus iniciales.
class TeacherAvatar extends StatelessWidget {
  const TeacherAvatar({super.key, required this.teacher, this.radius = 20});
  final Contact teacher;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final initials = teacher.name
        .split(' ')
        .where((w) => w.isNotEmpty && !w.endsWith('.'))
        .take(2)
        .map((w) => w[0])
        .join();
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFF263042),
      foregroundImage: teacher.imageAsset.isEmpty
          ? null
          : ResizeImage(AssetImage(teacher.imageAsset), width: (radius * 6).round()),
      onForegroundImageError: teacher.imageAsset.isEmpty ? null : (_, __) {},
      child: Text(initials, style: TextStyle(color: const Color(0xFFE8A33D), fontSize: radius * 0.7)),
    );
  }
}
