import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:login_register_app/connection/Home/HomeController.dart';
import '../../connection/auth/AuthController.dart';
import 'dart:convert';
import 'package:login_register_app/utils/helpers/snackbar_helper.dart';
import 'package:login_register_app/values/app_routes.dart';
import '../../utils/helpers/navigation_helper.dart';
import 'package:login_register_app/widgets/workshop_card.dart';
import 'package:login_register_app/widgets/booking_form.dart';
import 'package:login_register_app/widgets/app_drawer.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final HomeController controller;
  
  // Search and filter variables
  final TextEditingController searchController = TextEditingController();
  bool isSearchVisible = false;
  String? selectedFilter;
  List<String> filterOptions = ['Nombre', 'Dirección'];

  // Añade esta lista de imágenes al inicio de la clase
  final List<String> defaultImages = [
    'assets/images/1.jpg',
    'assets/images/2.jpg',
    'assets/images/3.jpg',
    'assets/images/4.jpg',
    'assets/images/5.jpg',
    'assets/images/descarga.jpeg',
  ];

  // Método auxiliar para obtener la imagen según el índice
  String getImageForIndex(int index) {
    return defaultImages[index % defaultImages.length];
  }

  @override
  void initState() {
    super.initState();
    controller = HomeController();
    _loadWorkshops();
    
    // Add listener to search controller
    searchController.addListener(() {
      _applySearch();
    });
  }
  
  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
  
  Future<void> _loadWorkshops() async {
    try {
      await controller.fetchWorkshops();
      setState(() {});
    } catch (error) {
      print('Error loading workshops: $error');
    }
  }
  
  // Search method to filter workshops based on search text and selected filter
  void _applySearch() {
    setState(() {
      if (searchController.text.isEmpty) {
        controller.resetFilters();
      } else {
        final searchText = searchController.text.toLowerCase();
        
        controller.filterWorkshops((workshop) {
          switch (selectedFilter) {
            case 'Dirección':
              return workshop['direccion'] != null && 
                     workshop['direccion'].toString().toLowerCase().contains(searchText);
            
            case 'Nombre':
            default:
              return workshop['nombre'] != null && 
                     workshop['nombre'].toString().toLowerCase().contains(searchText);
          }
        });
      }
    });
  }
  
  // Method to toggle search visibility
  void _toggleSearch() {
    setState(() {
      isSearchVisible = !isSearchVisible;
      if (!isSearchVisible) {
        searchController.clear();
        controller.resetFilters();
      }
    });
  }

  void _showBookingBottomSheet(Map<String, dynamic> workshop) async {
    setState(() {
      controller.selectWorkshop(workshop);
    });
    
    final userId = await controller.getUserId();
    if (userId != null) {
      final vehicles = await controller.fetchUserVehicles(userId);
      
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setSheetState) {
              return BookingForm(
                workshop: workshop,
                vehicles: vehicles,
                onVehicleSelected: (value) => setSheetState(() => controller.setVehicle(value)),
                onDateSelected: (date) => setSheetState(() => controller.selectDate(date)),
                onTimeSelected: (time) => setSheetState(() => controller.selectTime(time)),
                onDescriptionChanged: controller.setAppointmentDescription,
                onBookingSubmitted: () async {
                                  final result = await controller.bookAppointment(context);
                                  if (result != null && result['success']) {
                    Navigator.of(context).pop();
                                    NavigationHelper.pushReplacementNamed(AppRoutes.appointmentsPage);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(result?['error'] ?? 'Error al agendar la cita'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                },
                selectedDate: controller.selectedDate,
                selectedTime: controller.selectedTime,
                selectedVehicle: controller.selectedVehicle,
                availableTimeSlots: controller.availableTimeSlots,
              );
            },
          );
        },
      );
    }
  }

  Future<bool> _showExitConfirmationDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Column(
          children: [
            Icon(Icons.warning_amber_rounded, size: 50, color: Colors.orange),
            SizedBox(height: 10),
            Text(
              '¿Desea salir?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: const Text(
          '¿Está seguro que desea salir de la aplicación?',
          textAlign: TextAlign.center,
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  textStyle: const TextStyle(fontSize: 16),
                ),
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  textStyle: const TextStyle(fontSize: 16),
                ),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Salir'),
              ),
            ],
          ),
        ],
      ),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        
        final shouldPop = await _showExitConfirmationDialog();
        
        if (shouldPop) {
          SystemNavigator.pop(); // This will close the app
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
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
          automaticallyImplyLeading: false, // Remove back button
          actions: [
            IconButton(
              icon: Icon(
                isSearchVisible ? Icons.close : Icons.search,
                color: Colors.white
              ),
              onPressed: _toggleSearch,
            ),
            IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () {
                _scaffoldKey.currentState?.openEndDrawer();
              },
            ),
          ],
        ),
        endDrawer: const AppDrawer(),
        body: Column(
          children: [
            // Search bar (conditionally visible)
            if (isSearchVisible)
              Container(
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
                    ),
                    const SizedBox(height: 8),
                    // Filter options
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
                                  setState(() {
                                    selectedFilter = selected ? filter : null;
                                    _applySearch(); // Apply filter when changed
                                  });
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
              ),
            
            // Workshop list
            Expanded(
              child: controller.getDisplayedWorkshops().isEmpty && controller.workshops.isNotEmpty
                ? Center(
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
                          onPressed: () {
                            searchController.clear();
                            setState(() {
                              selectedFilter = null;
                              controller.resetFilters();
                            });
                          },
                          child: const Text('Limpiar búsqueda'),
                        ),
                      ],
                    ),
                  )
                : controller.workshops.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : ListView.builder(
                      itemCount: controller.getDisplayedWorkshops().length,
                      itemBuilder: (context, index) {
                        final workshop = controller.getDisplayedWorkshops()[index];
                        return WorkshopCard(
                          workshop: workshop,
                          index: index,
                          defaultImages: defaultImages,
                          onBookingPressed: _showBookingBottomSheet,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}