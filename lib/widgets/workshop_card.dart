import 'package:flutter/material.dart';
import 'dart:convert';

class WorkshopCard extends StatelessWidget {
  final Map<String, dynamic> workshop;
  final int index;
  final List<String> defaultImages;
  final Function(Map<String, dynamic>) onBookingPressed;

  const WorkshopCard({
    Key? key,
    required this.workshop,
    required this.index,
    required this.defaultImages,
    required this.onBookingPressed,
  }) : super(key: key);

  String getImageForIndex(int index) {
    return defaultImages[index % defaultImages.length];
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.2),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Colors.grey.shade50],
          ),
        ),
        child: Column(
          children: [
            Container(
              height: 100,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                image: DecorationImage(
                  image: workshop['imagenes'] != null && workshop['imagenes'].isNotEmpty
                      ? MemoryImage(base64Decode(workshop['imagenes'][0]))
                      : AssetImage(getImageForIndex(index)) as ImageProvider,
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(0.3),
                    BlendMode.darken,
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      workshop['nombre'] ?? 'Sin nombre',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [Shadow(offset: Offset(0, 1), blurRadius: 3.0, color: Colors.black54)],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            workshop['direccion'] ?? 'No disponible',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              shadows: [Shadow(offset: Offset(0, 1), blurRadius: 2.0, color: Colors.black54)],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.access_time, size: 14, color: Colors.grey.shade700),
                        const SizedBox(width: 4),
                        Text(
                          '${workshop['abre']?.toString().substring(0, 5) ?? '08:00'} - ${workshop['cierra']?.toString().substring(0, 5) ?? '18:00'}',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => onBookingPressed(workshop),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade900,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 2,
                    ),
                    child: const Text(
                      'Agendar',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 