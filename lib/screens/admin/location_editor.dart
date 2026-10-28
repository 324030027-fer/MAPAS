import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/map_provider.dart';
import '../../models/map_location.dart';
import '../../widgets/glass.dart';

class LocationEditor extends StatefulWidget {
  final MapLocation location;

  const LocationEditor({super.key, required this.location});

  @override
  State<LocationEditor> createState() => _LocationEditorState();
}

class _LocationEditorState extends State<LocationEditor> {
  late TextEditingController titleController;
  late TextEditingController descController;
  late TextEditingController catController;
  late TextEditingController xController;
  late TextEditingController yController;
  late TextEditingController asset360Controller;
  late TextEditingController featuresController;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.location.title);
    descController = TextEditingController(text: widget.location.description);
    catController = TextEditingController(text: widget.location.category);
    xController = TextEditingController(text: widget.location.x.toString());
    yController = TextEditingController(text: widget.location.y.toString());
    asset360Controller = TextEditingController(text: widget.location.assetImage360);
    featuresController = TextEditingController(text: widget.location.features);
  }

  @override
  void dispose() {
    titleController.dispose();
    descController.dispose();
    catController.dispose();
    xController.dispose();
    yController.dispose();
    asset360Controller.dispose();
    featuresController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      forceDark: true,
      appBar: AppBar(
        title: const Text("Editar Ubicación"),
        backgroundColor: const Color(0xFF1E1E2C),
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFF1E1E2C),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildTextField(titleController, "Título"),
              _buildTextField(descController, "Descripción", maxLines: 3),
              _buildTextField(catController, "Categoría"),
              _buildTextField(xController, "Coordenada X (0-1)", keyboardType: TextInputType.number),
              _buildTextField(yController, "Coordenada Y (0-1)", keyboardType: TextInputType.number),
              _buildTextField(asset360Controller, "Ruta imagen 360"),
              _buildTextField(featuresController, "Características", maxLines: 3),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  final updated = widget.location.copyWith(
                    title: titleController.text,
                    description: descController.text,
                    category: catController.text,
                    x: double.tryParse(xController.text) ?? widget.location.x,
                    y: double.tryParse(yController.text) ?? widget.location.y,
                    assetImage360: asset360Controller.text,
                    features: featuresController.text,
                  );
                  Provider.of<MapProvider>(context, listen: false).updateMapPoint(updated);
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.save),
                label: const Text("Guardar Cambios"),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF8C00)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white24), borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Color(0xFFFF8C00)), borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}