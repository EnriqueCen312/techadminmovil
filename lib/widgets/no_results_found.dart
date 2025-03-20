import 'package:flutter/material.dart';

class NoResultsFound extends StatelessWidget {
  final VoidCallback onClearSearch;

  const NoResultsFound({
    Key? key,
    required this.onClearSearch,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 60, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No se encontraron talleres',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onClearSearch,
            child: const Text('Limpiar búsqueda'),
          ),
        ],
      ),
    );
  }
} 