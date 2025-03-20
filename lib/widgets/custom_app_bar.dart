import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool isSearchVisible;
  final VoidCallback onSearchToggle;
  final VoidCallback onMenuPressed;

  const CustomAppBar({
    Key? key,
    required this.isSearchVisible,
    required this.onSearchToggle,
    required this.onMenuPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Tech',
            style: TextStyle(
              color: Colors.orange.shade500,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Text(
            'Administrator',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
      backgroundColor: Colors.blue.shade900,
      automaticallyImplyLeading: false,
      actions: [
        IconButton(
          icon: Icon(
            isSearchVisible ? Icons.close : Icons.search,
            color: Colors.white
          ),
          onPressed: onSearchToggle,
        ),
        IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: onMenuPressed,
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
} 