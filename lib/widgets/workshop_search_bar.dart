import 'package:flutter/material.dart';

class WorkshopSearchBar extends StatelessWidget {
  final TextEditingController searchController;
  final String? selectedFilter;
  final List<String> filterOptions;
  final Function(String?) onFilterSelected;
  final VoidCallback onSearch;

  const WorkshopSearchBar({
    Key? key,
    required this.searchController,
    required this.selectedFilter,
    required this.filterOptions,
    required this.onFilterSelected,
    required this.onSearch,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.blue.shade800,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          TextField(
            controller: searchController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Buscar talleres...',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
              prefixIcon: const Icon(Icons.search, color: Colors.white),
              filled: true,
              fillColor: Colors.blue.shade700,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
            cursorColor: Colors.white,
            onChanged: (_) => onSearch(),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                const SizedBox(width: 4),
                for (String filter in filterOptions)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(filter),
                      selected: selectedFilter == filter,
                      onSelected: (selected) {
                        onFilterSelected(selected ? filter : null);
                      },
                      backgroundColor: Colors.blue.shade700,
                      selectedColor: Colors.orange.shade500,
                      labelStyle: TextStyle(
                        color: selectedFilter == filter 
                          ? Colors.white 
                          : Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 