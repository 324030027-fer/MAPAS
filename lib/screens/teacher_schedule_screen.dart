import 'package:flutter/material.dart';
import '../widgets/glass.dart';

class TeacherScheduleScreen extends StatefulWidget {
  const TeacherScheduleScreen({super.key});

  @override
  State<TeacherScheduleScreen> createState() => _TeacherScheduleScreenState();
}

class _TeacherScheduleScreenState extends State<TeacherScheduleScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> _days = ["Lunes", "Martes", "Miércoles", "Jueves", "Viernes"];

  // Datos de horarios organizados por día
  final Map<String, List<ScheduleItem>> _scheduleData = {
    "Lunes": [
      ScheduleItem(start: "08:00", end: "08:50", subject: "CONMUTACIÓN Y ENRUTAMIENTO DE REDES", group: "2A ITR", type: "Clase"),
      ScheduleItem(start: "08:50", end: "09:40", subject: "CONMUTACIÓN Y ENRUTAMIENTO DE REDES", group: "2A ITR", type: "Clase"),
      ScheduleItem(start: "10:30", end: "11:20", subject: "SEGURIDAD EN REDES Y TELECOMUNICACIONES", group: "8A IRT", type: "Clase"),
      ScheduleItem(start: "11:20", end: "12:10", subject: "SEGURIDAD EN REDES Y TELECOMUNICACIONES", group: "8A IRT", type: "Clase"),
      ScheduleItem(start: "12:10", end: "12:40", subject: "ALIMENTOS", group: "", type: "Receso"),
      ScheduleItem(start: "12:40", end: "13:50", subject: "GESTIÓN ACADÉMICA", group: "", type: "Gestión"),
      ScheduleItem(start: "13:50", end: "15:30", subject: "PROYECTOS ESPECIALES", group: "", type: "Proyecto"),
    ],
    "Martes": [
      ScheduleItem(start: "08:00", end: "08:50", subject: "SEGURIDAD EN REDES", group: "5A ITR", type: "Clase"),
      ScheduleItem(start: "08:50", end: "09:40", subject: "CONMUTACIÓN Y ENRUTAMIENTO DE REDES", group: "2A ITR", type: "Clase"),
      ScheduleItem(start: "09:40", end: "10:30", subject: "SEGURIDAD EN REDES Y TELECOMUNICACIONES", group: "8A IRT", type: "Clase"),
      ScheduleItem(start: "10:30", end: "11:20", subject: "SEGURIDAD EN REDES Y TELECOMUNICACIONES", group: "8B IRT", type: "Clase"),
      ScheduleItem(start: "11:20", end: "12:10", subject: "ASESORÍAS", group: "", type: "Asesoría"),
      ScheduleItem(start: "12:10", end: "12:40", subject: "ALIMENTOS", group: "", type: "Receso"),
      ScheduleItem(start: "12:40", end: "13:50", subject: "GESTIÓN ACADÉMICA", group: "", type: "Gestión"),
      ScheduleItem(start: "13:50", end: "15:30", subject: "PROYECTOS ESPECIALES", group: "", type: "Proyecto"),
    ],
    "Miércoles": [
      ScheduleItem(start: "08:00", end: "08:50", subject: "SEGURIDAD EN REDES", group: "5A ITR", type: "Clase"),
      ScheduleItem(start: "08:50", end: "09:40", subject: "CONMUTACIÓN Y ENRUTAMIENTO DE REDES", group: "2A ITR", type: "Clase"),
      ScheduleItem(start: "09:40", end: "10:30", subject: "SEGURIDAD EN REDES Y TELECOMUNICACIONES", group: "6A IRT", type: "Clase"),
      ScheduleItem(start: "10:30", end: "11:20", subject: "SEGURIDAD EN REDES Y TELECOMUNICACIONES", group: "8A IRT", type: "Clase"),
      ScheduleItem(start: "11:20", end: "12:10", subject: "ASESORÍAS", group: "", type: "Asesoría"),
      ScheduleItem(start: "12:10", end: "12:40", subject: "ALIMENTOS", group: "", type: "Receso"),
      ScheduleItem(start: "12:40", end: "13:50", subject: "GESTIÓN ACADÉMICA", group: "8A IRT", type: "Gestión"),
      ScheduleItem(start: "13:50", end: "15:30", subject: "PROYECTOS ESPECIALES", group: "8A IRT", type: "Proyecto"),
    ],
    "Jueves": [
      ScheduleItem(start: "08:00", end: "08:50", subject: "SEGURIDAD EN REDES", group: "5A ITR", type: "Clase"),
      ScheduleItem(start: "08:50", end: "09:40", subject: "CONMUTACIÓN Y ENRUTAMIENTO DE REDES", group: "2A ITR", type: "Clase"),
      ScheduleItem(start: "09:40", end: "10:30", subject: "GESTIÓN ACADÉMICA", group: "", type: "Gestión"),
      ScheduleItem(start: "10:30", end: "11:20", subject: "ASESORÍAS", group: "", type: "Asesoría"),
      ScheduleItem(start: "11:20", end: "12:10", subject: "ASESORÍAS", group: "", type: "Asesoría"),
      ScheduleItem(start: "12:10", end: "12:40", subject: "ALIMENTOS", group: "", type: "Receso"),
      ScheduleItem(start: "12:40", end: "13:50", subject: "GESTIÓN ACADÉMICA", group: "", type: "Gestión"),
      ScheduleItem(start: "13:50", end: "15:30", subject: "PROYECTOS ESPECIALES", group: "", type: "Proyecto"),
    ],
    "Viernes": [
      ScheduleItem(start: "08:00", end: "08:50", subject: "SEGURIDAD EN REDES", group: "5A ITR", type: "Clase"),
      ScheduleItem(start: "08:50", end: "09:40", subject: "SEGURIDAD EN REDES", group: "5A ITR", type: "Clase"),
      ScheduleItem(start: "09:40", end: "10:30", subject: "GESTIÓN ACADÉMICA", group: "", type: "Gestión"),
      ScheduleItem(start: "10:30", end: "11:20", subject: "ASESORÍAS", group: "", type: "Asesoría"),
      ScheduleItem(start: "11:20", end: "12:10", subject: "ASESORÍA", group: "", type: "Asesoría"),
      ScheduleItem(start: "12:10", end: "12:40", subject: "ALIMENTOS", group: "", type: "Receso"),
      ScheduleItem(start: "12:40", end: "13:50", subject: "GESTIÓN ACADÉMICA", group: "", type: "Gestión"),
      ScheduleItem(start: "13:50", end: "15:30", subject: "PROYECTOS ESPECIALES", group: "", type: "Proyecto"),
    ],
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _days.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      forceDark: true,
      backgroundColor: const Color(0xFF1E1E2C),
      body: SafeArea(
        child: Column(
          children: [
            // AppBar personalizada
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFFFF8C00).withOpacity(0.15),
                    const Color(0xFF1E1E2C),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF8C00).withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Color(0xFFFF8C00)),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFFF8C00), width: 2),
                      image: DecorationImage(
                        image: ResizeImage(AssetImage('assets/erickphoto.png'), width: 300),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Dr. Erick Montecillo",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "Horario de clases",
                          style: TextStyle(
                            color: const Color(0xFFFF8C00),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // TabBar (pestañas) y TabBarView (contenido deslizable)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF2D2D44),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: false,
                  indicator: BoxDecoration(
                    color: const Color(0xFFFF8C00),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                  tabs: _days.map((day) => Tab(text: day)).toList(),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // TabBarView con los horarios de cada día (permite deslizar)
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: _days.map((day) {
                  final items = _scheduleData[day] ?? [];
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    itemBuilder: (ctx, index) {
                      final item = items[index];
                      return _ScheduleCard(
                        startTime: item.start,
                        endTime: item.end,
                        subject: item.subject,
                        group: item.group,
                        type: item.type,
                      );
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Modelo de datos
class ScheduleItem {
  final String start;
  final String end;
  final String subject;
  final String group;
  final String type;

  ScheduleItem({
    required this.start,
    required this.end,
    required this.subject,
    required this.group,
    required this.type,
  });
}

// Tarjeta individual de clase (sin cambios)
class _ScheduleCard extends StatelessWidget {
  final String startTime;
  final String endTime;
  final String subject;
  final String group;
  final String type;

  const _ScheduleCard({
    required this.startTime,
    required this.endTime,
    required this.subject,
    required this.group,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 12),
      radius: 20,
      blur: 14,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Columna de hora
            Container(
              width: 80,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2C),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    startTime,
                    style: const TextStyle(
                      color: Color(0xFFFF8C00),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const Text(
                    "a",
                    style: TextStyle(color: Colors.white54, fontSize: 10),
                  ),
                  Text(
                    endTime,
                    style: const TextStyle(
                      color: Color(0xFFFF8C00),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Información de la clase
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subject,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (group.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF8C00).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        group,
                        style: const TextStyle(
                          color: Color(0xFFFF8C00),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    type,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            // Icono según tipo
            Icon(
              type == "Receso" ? Icons.free_breakfast :
              type == "Proyecto" ? Icons.assignment :
              type == "Asesoría" ? Icons.people :
              Icons.school,
              color: const Color(0xFFFF8C00).withOpacity(0.7),
              size: 28,
            ),
          ],
        ),
      ),
    );
  }
}