import 'package:flutter/material.dart';
import 'package:panorama/panorama.dart';
import 'package:provider/provider.dart';
import '../models/map_location.dart';
import '../providers/map_provider.dart';

class PanoramaViewer extends StatefulWidget {
  final MapLocation initialLocation;
  const PanoramaViewer({super.key, required this.initialLocation});
  
  @override
  State<PanoramaViewer> createState() => _PanoramaViewerState();
}

class _PanoramaViewerState extends State<PanoramaViewer> {
  late MapLocation currentLocation;
  
  @override
  void initState() {
    super.initState();
    currentLocation = widget.initialLocation;
  }

  void _navigateTo(String targetId) {
    final provider = Provider.of<MapProvider>(context, listen: false);
    setState(() {
      currentLocation = provider.getTourLocationById(targetId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MapProvider>(context, listen: false);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent, 
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8), 
          decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle), 
          child: const BackButton(color: Colors.white)
        ),
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), 
          decoration: BoxDecoration(
            color: Colors.black45, 
            borderRadius: BorderRadius.circular(20), 
            border: Border.all(color: Colors.white24)
          ), 
          child: Text(
            currentLocation.title, 
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)
          )
        ),
        centerTitle: true,
      ),
      body: Panorama(
        
        key: ValueKey(currentLocation.assetImage360),
        zoom: 1.0, 
        animSpeed: 0.0, 
        sensitivity: 2.0,
        child: Image.asset(currentLocation.assetImage360),
        hotspots: currentLocation.hotspotLinks.map((link) {
          final linkedLoc = provider.getTourLocationById(link.targetId);
          return Hotspot(
            latitude: link.pitch, 
            longitude: link.yaw, 
            width: 90, 
            height: 90,
            widget: GestureDetector(
              onTap: () => _navigateTo(link.targetId),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6C63FF).withOpacity(0.5),
                          blurRadius: 15
                        )
                      ]
                    ),
                    child: const Icon(Icons.arrow_upward_sharp, color: Color(0xFF6C63FF), size: 36),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.white24)
                    ),
                    child: Text(
                      "Ir a ${linkedLoc.title}",
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
